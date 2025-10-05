# frozen_string_literal: true

# Merchant Product model
# Represents a product/service in a merchant's catalog
class MerchantProduct < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :invoice_items, class_name: "MerchantInvoiceItem", foreign_key: "product_id", dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :default_price_cents, presence: true, numericality: { greater_than: 0 }
  validates :unit_type, presence: true, inclusion: { in: %w[item hour day week month year] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :search, ->(query) {
    where("name LIKE ? OR description LIKE ?", "%#{sanitize_sql_like(query)}%", "%#{sanitize_sql_like(query)}%") if query.present?
  }

  # Convert price to dollars
  def default_price_dollars
    default_price_cents / 100.0
  end

  # Set price from dollars
  def default_price_dollars=(value)
    self.default_price_cents = (value.to_f * 100).to_i
  end

  # Check if product is synced to Stripe
  def synced_to_stripe?
    stripe_product_id.present?
  end

  # Get formatted unit type
  def unit_type_display
    unit_type.humanize
  end

  # Formatted price with unit
  def price_with_unit
    "$#{sprintf('%.2f', default_price_dollars)} / #{unit_type}"
  end

  # Archive product instead of deleting
  def archive!
    update(active: false)
  end

  # Unarchive product
  def unarchive!
    update(active: true)
  end
end
