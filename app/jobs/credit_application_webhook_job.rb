class CreditApplicationWebhookJob < ApplicationJob
  queue_as :default

  def perform(event)
    Rails.logger.info "Processing credit application webhook: #{event.type}"

    case event.type
    when "stripe.invoice.created"
      handle_invoice_created(event)
    else
      Rails.logger.warn "Unknown event type for credit application: #{event.type}"
    end
  rescue => e
    Rails.logger.error "Failed to process credit application webhook: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    # Don't re-raise for credit application failures to avoid blocking invoice processing
  end

  private

  def handle_invoice_created(event)
    invoice_data = event.data["object"]
    customer_id = invoice_data["customer"]
    invoice_id = invoice_data["id"]

    # Skip if not a subscription invoice
    return unless invoice_data["subscription"]

    # Find the user associated with this customer
    pay_customer = Pay::Customer.find_by(processor_id: customer_id)
    return unless pay_customer

    user = pay_customer.owner
    return unless user

    # Check if user has available credits
    return unless user.available_credit_balance > 0

    Rails.logger.info "Applying credits for user #{user.id} to invoice #{invoice_id}"
    CreditApplicationService.apply_credits_to_invoice(invoice_id, user)
  end
end
