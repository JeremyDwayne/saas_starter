# frozen_string_literal: true

# Merchant Invoice model
# Represents an invoice sent by a merchant to their customer
class MerchantInvoice < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :customer, class_name: "MerchantCustomer", foreign_key: "customer_id"
  has_many :invoice_items, class_name: "MerchantInvoiceItem", foreign_key: "invoice_id", dependent: :destroy

  # Accepts nested attributes for line items
  accepts_nested_attributes_for :invoice_items, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :invoice_number, presence: true, uniqueness: { scope: :user_id }
  validates :status, presence: true, inclusion: { in: %w[draft open paid void uncollectible] }
  validates :days_until_due, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Callbacks
  before_validation :generate_invoice_number, on: :create
  before_save :calculate_totals

  # Scopes
  scope :draft, -> { where(status: "draft") }
  scope :open, -> { where(status: "open") }
  scope :paid, -> { where(status: "paid") }
  scope :void, -> { where(status: "void") }
  scope :recent, -> { order(created_at: :desc) }
  scope :overdue, -> { where(status: "open").where("due_date < ?", Date.today) }
  scope :unpaid, -> { where(status: %w[draft open]) }

  # Generate next invoice number for this merchant
  def generate_invoice_number
    return if invoice_number.present?

    last_invoice = user.invoices.order(:created_at).last
    next_number = last_invoice ? last_invoice.invoice_number.to_i + 1 : 1
    self.invoice_number = format("%06d", next_number)
  end

  # Calculate subtotal, tax, and total from line items
  def calculate_totals
    self.subtotal_cents = invoice_items.sum(&:amount_cents)
    # Tax calculation can be added here if needed
    self.total_cents = subtotal_cents + tax_cents
  end

  # Calculate application fee based on platform fee percentage
  def calculate_application_fee
    fee_calculation = FeeCalculationService.calculate_for_user(user, total_cents)
    self.application_fee_cents = fee_calculation[:fee_cents]
  end

  # Status helpers
  def draft?
    status == "draft"
  end

  def open?
    status == "open"
  end

  def paid?
    status == "paid"
  end

  def void?
    status == "void"
  end

  def overdue?
    open? && due_date && due_date < Date.today
  end

  # Amount helpers
  def subtotal_dollars
    subtotal_cents / 100.0
  end

  def tax_dollars
    tax_cents / 100.0
  end

  def total_dollars
    total_cents / 100.0
  end

  def application_fee_dollars
    application_fee_cents / 100.0
  end

  # Set the due date based on days_until_due
  def set_due_date
    self.due_date = Date.today + days_until_due.days if days_until_due
  end

  # Check if invoice is synced to Stripe
  def synced_to_stripe?
    stripe_invoice_id.present?
  end

  # Mark invoice as sent
  def mark_as_sent!
    update(status: "open", sent_at: Time.current)
    set_due_date if due_date.blank?
    save
  end

  # Mark invoice as paid
  def mark_as_paid!
    update(status: "paid", paid_at: Time.current)
  end

  # Mark invoice as void
  def mark_as_void!
    update(status: "void", voided_at: Time.current)
  end
end
