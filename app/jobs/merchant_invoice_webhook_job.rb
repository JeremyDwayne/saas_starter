# frozen_string_literal: true

# Merchant Invoice Webhook Job
# Handles Stripe webhook events for Connect invoices
class MerchantInvoiceWebhookJob < ApplicationJob
  queue_as :default

  def perform(event)
    case event.type
    when "invoice.paid"
      handle_invoice_paid(event)
    when "invoice.payment_failed"
      handle_invoice_payment_failed(event)
    when "invoice.voided"
      handle_invoice_voided(event)
    when "invoice.marked_uncollectible"
      handle_invoice_marked_uncollectible(event)
    end
  end

  private

  def handle_invoice_paid(event)
    stripe_invoice = event.data.object
    invoice = find_invoice(stripe_invoice.id)

    return unless invoice

    invoice.mark_as_paid!
    Rails.logger.info "Invoice #{invoice.invoice_number} marked as paid via webhook"
  end

  def handle_invoice_payment_failed(event)
    stripe_invoice = event.data.object
    invoice = find_invoice(stripe_invoice.id)

    return unless invoice

    # Keep status as open but log the failure
    Rails.logger.warn "Payment failed for invoice #{invoice.invoice_number}"
    # Could send notification to merchant here
  end

  def handle_invoice_voided(event)
    stripe_invoice = event.data.object
    invoice = find_invoice(stripe_invoice.id)

    return unless invoice

    invoice.mark_as_void!
    Rails.logger.info "Invoice #{invoice.invoice_number} voided via webhook"
  end

  def handle_invoice_marked_uncollectible(event)
    stripe_invoice = event.data.object
    invoice = find_invoice(stripe_invoice.id)

    return unless invoice

    invoice.update(status: "uncollectible")
    Rails.logger.info "Invoice #{invoice.invoice_number} marked as uncollectible"
  end

  def find_invoice(stripe_invoice_id)
    MerchantInvoice.find_by(stripe_invoice_id: stripe_invoice_id)
  end
end
