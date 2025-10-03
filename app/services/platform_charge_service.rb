# Platform charge service
# Creates Stripe charges on connected accounts with application fees
class PlatformChargeService
  class ChargeError < StandardError; end
  class OnboardingIncompleteError < StandardError; end
  class SubscriptionRequiredError < StandardError; end

  # Create a charge on a connected account with platform fee
  # @param merchant [User] The merchant user
  # @param amount_cents [Integer] Charge amount in cents
  # @param customer_email [String] Customer's email address
  # @param description [String] Charge description (optional)
  # @param metadata [Hash] Additional metadata (optional)
  # @return [Hash] Result with success status, charge, transaction, and fee_calculation
  def self.create_charge(merchant:, amount_cents:, customer_email:, description: nil, metadata: {})
    new(merchant, amount_cents, customer_email, description, metadata).create_charge
  end

  def initialize(merchant, amount_cents, customer_email, description, metadata)
    @merchant = merchant
    @amount_cents = amount_cents
    @customer_email = customer_email
    @description = description || "Payment processed via platform"
    @metadata = metadata || {}
  end

  # Create the charge and record transaction
  # @return [Hash] Result hash with charge and transaction details
  def create_charge
    validate_merchant!

    fee_calculation = calculate_fee

    begin
      # Create charge on connected account with application fee
      charge = Stripe::Charge.create({
        amount: @amount_cents,
        currency: "usd",
        description: @description,
        receipt_email: @customer_email,
        metadata: @metadata.merge({
          merchant_id: @merchant.id,
          merchant_email: @merchant.email,
          platform_charge: true
        }),
        application_fee_amount: fee_calculation[:fee_cents]
      }, {
        stripe_account: @merchant.merchant_processor.processor_id
      })

      # Record transaction
      transaction = record_transaction(charge, fee_calculation)

      {
        success: true,
        charge: charge,
        transaction: transaction,
        fee_calculation: fee_calculation
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Platform charge failed: #{e.message}"
      raise ChargeError, e.message
    end
  end

  private

  # Validate merchant can accept payments
  # @raise [OnboardingIncompleteError] If merchant onboarding not complete
  # @raise [SubscriptionRequiredError] If merchant has no active subscription
  def validate_merchant!
    unless @merchant.merchant_onboarding_complete?
      raise OnboardingIncompleteError, "Merchant must complete Stripe Connect onboarding"
    end

    unless @merchant.on_trial_or_subscribed?
      raise SubscriptionRequiredError, "Merchant must have an active subscription"
    end
  end

  # Calculate fee using FeeCalculationService
  # @return [Hash] Fee calculation breakdown
  def calculate_fee
    FeeCalculationService.calculate_for_user(@merchant, @amount_cents)
  end

  # Record transaction in database
  # @param charge [Stripe::Charge] The Stripe charge object
  # @param fee_calculation [Hash] Fee calculation breakdown
  # @return [PlatformTransaction] The created transaction record
  def record_transaction(charge, fee_calculation)
    PlatformTransaction.create!(
      merchant: @merchant,
      stripe_charge_id: charge.id,
      charge_amount_cents: @amount_cents,
      application_fee_cents: fee_calculation[:fee_cents],
      fee_percentage_applied: fee_calculation[:fee_percentage],
      customer_email: @customer_email,
      description: @description,
      metadata: @metadata,
      status: "succeeded"
    )
  end
end
