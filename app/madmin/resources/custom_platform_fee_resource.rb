class CustomPlatformFeeResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :user, class_name: "User"
  attribute :fee_percentage
  attribute :minimum_fee_cents
  attribute :notes
  attribute :expires_at
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Display
  def self.display_name(plural: false)
    plural ? "Custom Platform Fees" : "Custom Platform Fee"
  end

  def display_name
    "#{user.email} - #{fee_percentage}%"
  end

  # Scopes
  scope :active

  # Navigation
  def self.navigation_name
    "Custom Fees"
  end

  def self.navigation_icon
    "user-check"
  end

  # Custom display for minimum fee
  def minimum_fee_display
    minimum_fee_cents ? "$#{sprintf('%.2f', minimum_fee_cents / 100.0)}" : "None"
  end

  # Custom display for expiration
  def expiration_status
    return "Active" unless expires_at
    expires_at > Date.today ? "Active until #{expires_at}" : "Expired"
  end
end
