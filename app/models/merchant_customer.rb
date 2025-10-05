# frozen_string_literal: true

# Merchant Customer model
# Represents a customer of a merchant for invoicing purposes
class MerchantCustomer < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :invoices, class_name: "MerchantInvoice", foreign_key: "customer_id", dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :user_id, message: "already exists for this merchant" }
  validates :country, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :search, ->(query) {
    where("name LIKE ? OR email LIKE ?", "%#{sanitize_sql_like(query)}%", "%#{sanitize_sql_like(query)}%") if query.present?
  }

  # Get full address as single string
  def full_address
    [
      address_line1,
      address_line2,
      [ city, state ].compact.join(", "),
      postal_code,
      country
    ].select(&:present?).join("\n")
  end

  # Get formatted name with email
  def name_with_email
    "#{name} <#{email}>"
  end

  # Check if customer has a Stripe ID synced
  def synced_to_stripe?
    stripe_customer_id.present?
  end
end
