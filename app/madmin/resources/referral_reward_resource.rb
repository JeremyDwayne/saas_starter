class ReferralRewardResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :referrer, class_name: "User"
  attribute :referee, class_name: "User"
  attribute :subscription_id
  attribute :amount
  attribute :status
  attribute :earned_at
  attribute :used_at, form: false
  attribute :notes
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Display
  def self.display_name(plural: false)
    plural ? "Referral Rewards" : "Referral Reward"
  end

  def display_name
    "$#{sprintf('%.2f', amount / 100.0)} - #{referrer.email} → #{referee.email}"
  end

  # Scopes
  scope :available
  scope :used
  scope :pending
  scope :expired

  # Navigation
  def self.navigation_name
    "Referral Rewards"
  end

  def self.navigation_icon
    "dollar-sign"
  end

  # Custom display for amount
  def amount_display
    "$#{sprintf('%.2f', amount / 100.0)}"
  end
end
