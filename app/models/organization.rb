class Organization < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :organization_invitations, dependent: :destroy
  has_one :onboarding, dependent: :destroy

  # Business data associations
  has_many :merchant_customers, dependent: :destroy
  has_many :merchant_products, dependent: :destroy
  has_many :merchant_invoices, dependent: :destroy
  has_many :platform_transactions, dependent: :destroy
  has_many :custom_platform_fees, dependent: :destroy
  has_one :custom_platform_fee, -> { order(created_at: :desc) }, class_name: "CustomPlatformFee"

  # Pay gem - subscriptions and Connect accounts
  pay_customer stripe_attributes: ->(pay_customer) { { metadata: { organization_id: pay_customer.owner_id } } }
  pay_merchant

  # Pay gem requires an email method for Stripe checkout
  def email
    owner&.email_address
  end

  # Validations
  validates :name, presence: true
  validates :slug, uniqueness: true, allow_nil: true

  # Callbacks
  before_validation :generate_slug, on: :create
  after_commit :clear_members_organization_cache, if: :saved_change_to_name?

  # Subscription helper methods (delegated from User model for organization-level subscriptions)
  def subscribed?
    Rails.cache.fetch("organization/#{id}/subscribed", expires_in: 5.minutes) do
      # Check if organization has any active subscription (including trials)
      return false unless payment_processor
      payment_processor.subscriptions.active.any?
    end
  end

  def subscription
    Rails.cache.fetch("organization/#{id}/subscription", expires_in: 5.minutes) do
      # Get the most recent active subscription
      return nil unless payment_processor
      payment_processor.subscriptions.active.order(created_at: :desc).first
    end
  end

  def on_trial?
    Rails.cache.fetch("organization/#{id}/on_trial", expires_in: 5.minutes) do
      # Check if any subscription is on trial
      return false unless payment_processor
      payment_processor.subscriptions.on_trial.any?
    end
  end

  def on_trial_or_subscribed?
    subscribed? || on_trial?
  end

  def can_accept_payments?
    pay_merchant_processor&.connected?
  end

  def merchant_onboarding_complete?
    return false unless merchant_processor
    merchant_processor.onboarding_complete?
  rescue
    false
  end

  # Platform fee methods (delegated from User model for organization-level fees)
  def platform_fee_percentage
    Rails.cache.fetch("organization/#{id}/platform_fee_percentage", expires_in: 1.hour) do
      # Check for custom fee first
      custom_fee = custom_platform_fee
      return custom_fee.fee_percentage if custom_fee&.active?

      # Fall back to tier-based fee
      tier = current_subscription_tier
      config = PlatformFeeConfiguration.fee_for_tier(tier)
      config&.fee_percentage || default_platform_fee_percentage
    end
  end

  def current_subscription_tier
    return "none" unless subscription

    # Extract tier from subscription metadata or name
    subscription.name&.downcase || "none"
  end

  def default_platform_fee_percentage
    7.0 # Highest fee for organizations without subscription
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

  # Onboarding helper methods
  def has_onboarding?
    onboarding.present?
  end

  def onboarding_complete?
    return false unless has_onboarding?
    onboarding.complete?
  end

  def onboarding_progress
    return 0 unless has_onboarding?
    onboarding.progress_percentage
  end

  def needs_onboarding?
    !onboarding_complete? && on_trial_or_subscribed?
  end

  private

  def clear_platform_fee_cache
    Rails.cache.delete("organization/#{id}/platform_fee_percentage")
  end

  def clear_subscription_cache
    Rails.cache.delete("organization/#{id}/subscribed")
    Rails.cache.delete("organization/#{id}/subscription")
    Rails.cache.delete("organization/#{id}/on_trial")
  end

  def clear_members_organization_cache
    # Clear organization cache for all members when organization details change
    users.each do |user|
      user.send(:clear_organization_cache)
    end
  end

  def generate_slug
    return if slug.present?

    base_slug = name.to_s.parameterize
    candidate_slug = base_slug
    counter = 1

    while Organization.exists?(slug: candidate_slug)
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
