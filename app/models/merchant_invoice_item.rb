# frozen_string_literal: true

# Merchant Invoice Item model
# Represents a line item on an invoice
class MerchantInvoiceItem < ApplicationRecord
  # Associations
  belongs_to :invoice, class_name: "MerchantInvoice", foreign_key: "invoice_id"
  belongs_to :product, class_name: "MerchantProduct", foreign_key: "product_id", optional: true

  # Validations
  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :set_defaults_from_product, on: :create, if: :product
  before_validation :calculate_amount

  # Set description and unit price from product if not provided
  def set_defaults_from_product
    self.description ||= product.name
    self.unit_price_cents ||= product.default_price_cents
  end

  # Calculate amount_cents from quantity * unit_price_cents
  def calculate_amount
    self.amount_cents = (quantity.to_f * unit_price_cents).to_i if quantity && unit_price_cents
  end

  # Amount helpers
  def unit_price_dollars
    return nil if unit_price_cents.nil?
    unit_price_cents / 100.0
  end

  def unit_price_dollars=(value)
    self.unit_price_cents = (value.to_f * 100).to_i
  end

  def amount_dollars
    return nil if amount_cents.nil?
    amount_cents / 100.0
  end

  # Check if item is from a product or custom
  def from_product?
    product.present?
  end

  def custom?
    product.blank?
  end
end
