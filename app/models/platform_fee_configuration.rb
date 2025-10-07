# Platform fee configuration model
# Manages tier-based platform fees for Stripe Connect charges
class PlatformFeeConfiguration < ApplicationRecord
  validates :subscription_tier, presence: true, uniqueness: true
  validates :fee_percentage, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :minimum_fee_cents, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }

  VALID_TIERS = %w[personal professional enterprise none].freeze
  validates :subscription_tier, inclusion: { in: VALID_TIERS }

  after_commit :clear_cache

  # Find fee configuration for a specific tier
  # @param tier [String, Symbol] The subscription tier name
  # @return [PlatformFeeConfiguration, nil] The fee configuration or nil
  def self.fee_for_tier(tier)
    normalized_tier = tier&.to_s&.downcase
    Rails.cache.fetch("platform_fee_config/tier/#{normalized_tier}", expires_in: 1.day) do
      active.find_by(subscription_tier: normalized_tier)
    end
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

  private

  def clear_cache
    # Clear cache for all valid tiers
    VALID_TIERS.each do |tier|
      Rails.cache.delete("platform_fee_config/tier/#{tier}")
    end
  end
end
