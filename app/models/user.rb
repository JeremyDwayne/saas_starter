class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :omni_auth_identities, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

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
    roles.exists?(name: role_name.to_s.downcase)
  end

  def has_permission?(permission_name)
    roles.joins(:permissions).exists?(permissions: { name: permission_name })
  end

  def has_permission_for?(resource, action)
    roles.joins(:permissions).exists?(permissions: { resource: resource, action: action })
  end

  def admin?
    has_role?(:admin)
  end

  def assign_role(role_name)
    role = Role.find_by(name: role_name.to_s.downcase)
    return false unless role

    user_roles.find_or_create_by(role: role)
    true
  end

  def remove_role(role_name)
    role = Role.find_by(name: role_name.to_s.downcase)
    return false unless role

    user_roles.where(role: role).destroy_all
    true
  end

  def role_names
    roles.pluck(:name)
  end
end
