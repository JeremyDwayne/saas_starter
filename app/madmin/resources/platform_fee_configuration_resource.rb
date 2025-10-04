class PlatformFeeConfigurationResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :subscription_tier
  attribute :fee_percentage
  attribute :minimum_fee_cents
  attribute :active
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Display
  def self.display_name(plural: false)
    plural ? "Platform Fee Configurations" : "Platform Fee Configuration"
  end

  def display_name
    "#{subscription_tier.titleize} - #{fee_percentage}%"
  end

  # Scopes
  scope :active

  # Navigation
  def self.navigation_name
    "Fee Configurations"
  end

  def self.navigation_icon
    "settings"
  end

  # Custom display for minimum fee
  def minimum_fee_display
    minimum_fee_cents ? "$#{sprintf('%.2f', minimum_fee_cents / 100.0)}" : "None"
  end
end
