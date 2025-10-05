# Fee calculation service
# Centralizes platform fee calculation logic for Stripe Connect charges
class FeeCalculationService
  # Calculate platform fee for an organization and charge amount
  # @param organization [Organization] The merchant organization
  # @param amount_cents [Integer] The charge amount in cents
  # @return [Hash] Fee breakdown with amount, fee, percentage, net amount, and source
  def self.calculate_for_organization(organization, amount_cents)
    new(organization, amount_cents).calculate
  end

  # Legacy method for backward compatibility
  # @deprecated Use calculate_for_organization instead
  def self.calculate_for_user(user, amount_cents)
    # For backward compatibility, try to find user's organization
    organization = user.organizations.first
    raise ArgumentError, "User has no organization" unless organization

    calculate_for_organization(organization, amount_cents)
  end

  def initialize(merchant, amount_cents)
    @merchant = merchant
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
    @merchant.calculate_platform_fee(@amount_cents)
  end

  # Get the fee percentage being applied
  # @return [Float] Fee percentage
  def fee_percentage
    @merchant.platform_fee_percentage
  end

  # Determine the source of the fee (custom, tier, or default)
  # @return [String] Fee source identifier
  def fee_source
    if @merchant.custom_platform_fee&.active?
      "custom"
    elsif @merchant.subscription
      "tier"
    else
      "default"
    end
  end
end
