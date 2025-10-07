class User < ApplicationRecord
  has_referrals
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :omni_auth_identities, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :earned_rewards, class_name: "ReferralReward", foreign_key: "referrer_id", dependent: :destroy
  has_many :generated_rewards, class_name: "ReferralReward", foreign_key: "referee_id", dependent: :destroy
  has_one :custom_platform_fee, dependent: :destroy
  has_many :platform_transactions, foreign_key: "merchant_id", dependent: :destroy
  has_many :customers, class_name: "MerchantCustomer", dependent: :destroy
  has_many :products, class_name: "MerchantProduct", dependent: :destroy
  has_many :invoices, class_name: "MerchantInvoice", dependent: :destroy
  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships

  pay_customer stripe_attributes: ->(pay_customer) { { metadata: { user_id: pay_customer.owner_id } } }
  pay_merchant

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            uniqueness: { case_sensitive: false }
  validates :password, on: [ :registration, :password_change ],
            presence: true,
            length: { minimum: 8, maximum: 72 }
  validates :password_confirmation, on: [ :registration, :password_change ],
            presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def self.create_from_oauth(auth)
    email = auth.info.email
    name = auth.info.name || auth.info.nickname || email.split("@").first
    avatar_url = auth.info.image

    user = self.new(
      email_address: email,
      name: name,
      avatar_url: avatar_url,
      password: SecureRandom.base64(64).truncate_bytes(64)
    )
    # Save without validation context (password validations won't apply)
    user.save
    user
  end

  def signed_in_with_oauth(auth)
    # Update user info when signing in with OAuth (if they link additional providers)
    update_attributes = {}

    # Only update name if we don't have one or if the OAuth provider has a better one
    if name.blank? || (auth.info.name.present? && name == email_address.split("@").first)
      update_attributes[:name] = auth.info.name || auth.info.nickname
    end

    # Update avatar if we don't have one or if the OAuth provider has a different one
    if avatar_url.blank? || avatar_url != auth.info.image
      update_attributes[:avatar_url] = auth.info.image
    end

    update(update_attributes) if update_attributes.any?
  end

  def pay_should_sync_customer?
    # super will invoke Pay's default (e-mail changed)
    super || self.saved_change_to_name?
  end

  # Pay gem expects an email method, but we use email_address
  def email
    email_address
  end

  # Convenience methods for subscription status
  def subscribed?
    # Check if user has any active subscription (including trials)
    return false unless payment_processor
    payment_processor.subscriptions.active.any?
  end

  def subscription
    # Get the most recent active subscription
    return nil unless payment_processor
    payment_processor.subscriptions.active.order(created_at: :desc).first
  end

  def on_trial?
    # Check if any subscription is on trial
    return false unless payment_processor
    payment_processor.subscriptions.on_trial.any?
  end

  def on_trial_or_subscribed?
    subscribed? || on_trial?
  end

  def has_role?(role_name)
    normalized_role = role_name.to_s.downcase
    Rails.cache.fetch("user/#{id}/role/#{normalized_role}", expires_in: 1.hour) do
      roles.exists?(name: normalized_role)
    end
  end

  def has_permission?(permission_name)
    Rails.cache.fetch("user/#{id}/permission/#{permission_name}", expires_in: 1.hour) do
      roles.joins(:permissions).exists?(permissions: { name: permission_name })
    end
  end

  def has_permission_for?(resource, action)
    Rails.cache.fetch("user/#{id}/permission/#{resource}/#{action}", expires_in: 1.hour) do
      roles.joins(:permissions).exists?(permissions: { resource: resource, action: action })
    end
  end

  def admin?
    has_role?(:admin)
  end

  def assign_role(role_name)
    role = Role.find_by(name: role_name.to_s.downcase)
    return false unless role

    result = user_roles.find_or_create_by(role: role)
    clear_role_permission_cache
    true
  end

  def remove_role(role_name)
    role = Role.find_by(name: role_name.to_s.downcase)
    return false unless role

    user_roles.where(role: role).destroy_all
    clear_role_permission_cache
    true
  end

  def role_names
    roles.pluck(:name)
  end

  # Check if user belongs to an organization (cached for performance)
  def has_organization?(organization_id)
    Rails.cache.fetch("user/#{id}/organization/#{organization_id}", expires_in: 1.hour) do
      organizations.exists?(id: organization_id)
    end
  end

  # Get cached list of organization IDs
  def organization_ids_cached
    Rails.cache.fetch("user/#{id}/organization_ids", expires_in: 1.hour) do
      organization_ids
    end
  end

  # Referral reward methods
  def available_credit_balance
    Rails.cache.fetch("user/#{id}/credits/available", expires_in: 5.minutes) do
      earned_rewards.available.sum(:amount)
    end
  end

  def available_credit_balance_dollars
    available_credit_balance / 100.0
  end

  def total_earned_credits
    Rails.cache.fetch("user/#{id}/credits/earned", expires_in: 5.minutes) do
      earned_rewards.sum(:amount)
    end
  end

  def total_earned_credits_dollars
    total_earned_credits / 100.0
  end

  def total_used_credits
    Rails.cache.fetch("user/#{id}/credits/used", expires_in: 5.minutes) do
      earned_rewards.used.sum(:amount)
    end
  end

  def total_used_credits_dollars
    total_used_credits / 100.0
  end

  def successful_referrals_count
    Rails.cache.fetch("user/#{id}/referrals/count", expires_in: 5.minutes) do
      earned_rewards.where.not(status: "pending").count
    end
  end

  # Platform fee methods
  def platform_fee_percentage
    # Check for custom fee first
    custom_fee = custom_platform_fee
    return custom_fee.fee_percentage if custom_fee&.active?

    # Fall back to tier-based fee
    tier = current_subscription_tier
    config = PlatformFeeConfiguration.fee_for_tier(tier)
    config&.fee_percentage || default_platform_fee_percentage
  end

  def calculate_platform_fee(amount_cents)
    custom_fee = custom_platform_fee
    if custom_fee&.active?
      return custom_fee.calculate_application_fee(amount_cents)
    end

    tier = current_subscription_tier
    config = PlatformFeeConfiguration.fee_for_tier(tier)

    if config
      config.calculate_application_fee(amount_cents)
    else
      # Default to highest fee if no subscription
      (amount_cents * (default_platform_fee_percentage / 100.0)).round
    end
  end

  def current_subscription_tier
    return "none" unless subscription

    # Extract tier from subscription metadata or name
    subscription.name&.downcase || "none"
  end

  def merchant_onboarding_complete?
    return false unless merchant_processor
    merchant_processor.onboarding_complete?
  rescue
    false
  end

  def can_accept_payments?
    merchant_onboarding_complete? && on_trial_or_subscribed?
  end

  private

  def clear_role_permission_cache
    # Clear all role and permission related caches for this user
    Rails.cache.delete_matched("user/#{id}/role/*")
    Rails.cache.delete_matched("user/#{id}/permission/*")
  end

  def clear_organization_cache
    # Clear organization membership caches for this user
    Rails.cache.delete_matched("user/#{id}/organization/*")
    Rails.cache.delete("user/#{id}/organization_ids")
  end

  def clear_referral_cache
    # Clear referral credit caches for this user
    Rails.cache.delete("user/#{id}/credits/available")
    Rails.cache.delete("user/#{id}/credits/earned")
    Rails.cache.delete("user/#{id}/credits/used")
    Rails.cache.delete("user/#{id}/referrals/count")
  end

  def default_platform_fee_percentage
    7.0 # Highest fee for users without subscription
  end
end
