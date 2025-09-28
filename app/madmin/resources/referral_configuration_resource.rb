class ReferralConfigurationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :name
  attribute :reward_percentage
  attribute :enabled
  attribute :max_credits_per_referral
  attribute :credit_expiry_days
  attribute :description
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Display
  def self.display_name(plural: false)
    plural ? "Referral Configurations" : "Referral Configuration"
  end

  def display_name
    name
  end

  # Scopes
  scope :enabled
  scope :disabled

  # Navigation
  def self.navigation_name
    "Referral Configurations"
  end

  def self.navigation_icon
    "gift"
  end
end
