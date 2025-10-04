# Connected Account Webhook Job
# Processes Stripe Connect account and charge events
class ConnectedAccountWebhookJob < ApplicationJob
  queue_as :default

  def perform(event)
    Rails.logger.info "Processing connected account webhook: #{event.type}"

    case event.type
    when "account.updated"
      handle_account_updated(event)
    when "charge.succeeded"
      handle_charge_succeeded(event)
    when "charge.refunded"
      handle_charge_refunded(event)
    else
      Rails.logger.debug "Unhandled connected account event type: #{event.type}"
    end
  rescue => e
    Rails.logger.error "Failed to process connected account webhook: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  # Handle account updates from Stripe Connect
  # Updates merchant onboarding status and capabilities
  def handle_account_updated(event)
    account_data = event.data["object"]
    account_id = account_data["id"]

    Rails.logger.info "Processing account update for: #{account_id}"

    # Find merchant by Stripe Connect account ID
    merchant_processor = Pay::Merchant.find_by(processor: :stripe, processor_id: account_id)

    return unless merchant_processor

    # Update account details (charges_enabled, payouts_enabled, etc.)
    # The Pay gem will handle syncing account status automatically
    Rails.logger.info "Account #{account_id} updated successfully"
  end

  # Handle successful charges
  # Note: PlatformChargeService already creates transactions when charges are made
  # This webhook handler is for redundancy and to catch any missed charges
  def handle_charge_succeeded(event)
    charge_data = event.data["object"]
    charge_id = charge_data["id"]

    Rails.logger.info "Processing successful charge: #{charge_id}"

    # Check if transaction already exists
    transaction = PlatformTransaction.find_by(stripe_charge_id: charge_id)

    if transaction
      Rails.logger.info "Transaction #{charge_id} already recorded"
      # Ensure status is correct
      transaction.update(status: "succeeded") if transaction.status != "succeeded"
    else
      Rails.logger.warn "Charge #{charge_id} not found in platform transactions - may have been created outside the platform"
      # Optionally create the transaction record here if needed
    end
  end

  # Handle charge refunds
  # Updates transaction status to refunded or partially_refunded
  def handle_charge_refunded(event)
    charge_data = event.data["object"]
    charge_id = charge_data["id"]
    amount_refunded = charge_data["amount_refunded"]
    amount = charge_data["amount"]

    Rails.logger.info "Processing refund for charge: #{charge_id}"

    transaction = PlatformTransaction.find_by(stripe_charge_id: charge_id)

    unless transaction
      Rails.logger.warn "Transaction not found for charge: #{charge_id}"
      return
    end

    # Determine refund status
    if amount_refunded >= amount
      transaction.update(status: "refunded")
      Rails.logger.info "Charge #{charge_id} marked as fully refunded"
    else
      transaction.update(status: "partially_refunded")
      Rails.logger.info "Charge #{charge_id} marked as partially refunded"
    end
  end
end
