# Platform transaction model
# Tracks all Stripe Connect charges and application fees
class PlatformTransaction < ApplicationRecord
  belongs_to :merchant, class_name: "User", foreign_key: "merchant_id"
  belongs_to :organization

  validates :stripe_charge_id, presence: true, uniqueness: true
  validates :charge_amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :application_fee_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fee_percentage_applied, presence: true
  validates :status, presence: true, inclusion: { in: %w[succeeded refunded partially_refunded] }

  scope :succeeded, -> { where(status: "succeeded") }
  scope :refunded, -> { where(status: "refunded") }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
  scope :recent, -> { order(created_at: :desc) }

  # Get charge amount in dollars
  # @return [Float] The charge amount in dollars
  def charge_amount_dollars
    charge_amount_cents / 100.0
  end

  # Get application fee in dollars
  # @return [Float] The application fee in dollars
  def application_fee_dollars
    application_fee_cents / 100.0
  end

  # Calculate net amount after application fee
  # @return [Integer] The net amount in cents
  def net_amount_cents
    charge_amount_cents - application_fee_cents
  end

  # Get net amount in dollars
  # @return [Float] The net amount in dollars
  def net_amount_dollars
    net_amount_cents / 100.0
  end

  # Check if transaction is refunded
  # @return [Boolean] True if status is refunded
  def refunded?
    status == "refunded"
  end

  # Check if transaction is partially refunded
  # @return [Boolean] True if status is partially_refunded
  def partially_refunded?
    status == "partially_refunded"
  end

  # Check if transaction is successful
  # @return [Boolean] True if status is succeeded
  def succeeded?
    status == "succeeded"
  end
end
