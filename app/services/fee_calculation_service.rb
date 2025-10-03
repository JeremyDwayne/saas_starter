# Fee calculation service
# Centralizes platform fee calculation logic for Stripe Connect charges
class FeeCalculationService
  # Calculate platform fee for a user and charge amount
  # @param user [User] The merchant user
  # @param amount_cents [Integer] The charge amount in cents
  # @return [Hash] Fee breakdown with amount, fee, percentage, net amount, and source
  def self.calculate_for_user(user, amount_cents)
    new(user, amount_cents).calculate
  end

  def initialize(user, amount_cents)
    @user = user
    @amount_cents = amount_cents
  end

  # Calculate fee breakdown
  # @return [Hash] Fee calculation details
  def calculate
    {
      amount_cents: @amount_cents,
      fee_cents: fee_amount,
      fee_percentage: fee_percentage,
      net_amount_cents: @amount_cents - fee_amount,
      fee_source: fee_source
    }
  end

  private

  # Get the calculated fee amount in cents
  # @return [Integer] Fee amount in cents
  def fee_amount
    @user.calculate_platform_fee(@amount_cents)
  end

  # Get the fee percentage being applied
  # @return [Float] Fee percentage
  def fee_percentage
    @user.platform_fee_percentage
  end

  # Determine the source of the fee (custom, tier, or default)
  # @return [String] Fee source identifier
  def fee_source
    if @user.custom_platform_fee&.active?
      "custom"
    elsif @user.subscription
      "tier"
    else
      "default"
    end
  end
end
