# Custom platform fee model
# Allows per-user fee overrides for negotiated rates
class CustomPlatformFee < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :fee_percentage, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :minimum_fee_cents, numericality: { greater_than: 0 }, allow_nil: true
  validates :user_id, uniqueness: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Date.current) }

  # Check if the custom fee is still active
  # @return [Boolean] True if not expired
  def active?
    expires_at.nil? || expires_at > Date.current
  end

  # Calculate application fee for a charge amount
  # @param charge_amount_cents [Integer] The charge amount in cents
  # @return [Integer] The application fee amount in cents
  def calculate_application_fee(charge_amount_cents)
    fee = (charge_amount_cents * (fee_percentage / 100.0)).round

    if minimum_fee_cents.present?
      [ fee, minimum_fee_cents ].max
    else
      fee
    end
  end

  # Display fee percentage as a string
  # @return [String] Fee percentage with % symbol
  def fee_percentage_display
    "#{fee_percentage}%"
  end
end
