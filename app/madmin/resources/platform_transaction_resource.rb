class PlatformTransactionResource < Madmin::Resource
  # Attributes
  attribute :id, form: false
  attribute :merchant, class_name: "User"
  attribute :stripe_charge_id, form: false
  attribute :charge_amount_cents
  attribute :application_fee_cents
  attribute :fee_percentage_applied
  attribute :customer_email
  attribute :description
  attribute :metadata
  attribute :status
  attribute :created_at, form: false
  attribute :updated_at, form: false

  # Display
  def self.display_name(plural: false)
    plural ? "Platform Transactions" : "Platform Transaction"
  end

  def display_name
    "#{stripe_charge_id} - $#{sprintf('%.2f', charge_amount_dollars)}"
  end

  # Scopes
  scope :succeeded
  scope :refunded
  scope :recent

  # Navigation
  def self.navigation_name
    "Transactions"
  end

  def self.navigation_icon
    "credit-card"
  end

  # Custom displays for amounts
  def charge_amount_display
    "$#{sprintf('%.2f', charge_amount_dollars)}"
  end

  def application_fee_display
    "$#{sprintf('%.2f', application_fee_dollars)}"
  end

  def net_amount_display
    "$#{sprintf('%.2f', net_amount_cents / 100.0)}"
  end

  # Status badge color
  def status_badge_color
    case status
    when "succeeded"
      "green"
    when "refunded"
      "red"
    when "partially_refunded"
      "yellow"
    else
      "gray"
    end
  end
end
