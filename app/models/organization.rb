class Organization < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :organization_invitations, dependent: :destroy

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

  # Subscription helper methods (delegated from User model for organization-level subscriptions)
  def subscribed?
    # Check if organization has any active subscription (including trials)
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
    # Check for custom fee first
    custom_fee = custom_platform_fee
    return custom_fee.fee_percentage if custom_fee&.active?

    # Fall back to tier-based fee
    tier = current_subscription_tier
    config = PlatformFeeConfiguration.fee_for_tier(tier)
    config&.fee_percentage || default_platform_fee_percentage
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

  private

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
