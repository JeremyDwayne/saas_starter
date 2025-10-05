# frozen_string_literal: true

# Invoice Service
# Handles Stripe invoice creation and synchronization for connected accounts
class InvoiceService
  class InvoiceError < StandardError; end

  # Send an invoice via Stripe
  # Creates invoice on connected account, adds line items, and sends to customer
  # @param invoice [MerchantInvoice] The invoice to send
  # @return [Hash] Result with success status and data
  def self.send_invoice(invoice)
    new(invoice).send_invoice
  end

  # Void an invoice on Stripe
  # @param invoice [MerchantInvoice] The invoice to void
  # @return [Hash] Result with success status
  def self.void_invoice(invoice)
    new(invoice).void_invoice
  end

  # Sync invoice status from Stripe
  # @param invoice [MerchantInvoice] The invoice to sync
  # @return [Hash] Result with success status
  def self.sync_invoice(invoice)
    new(invoice).sync_invoice
  end

  def initialize(invoice)
    @invoice = invoice
    @merchant = invoice.user
    @customer = invoice.customer
  end

  # Send invoice to customer via Stripe
  def send_invoice
    validate_merchant!

    begin
      # Ensure customer exists on Stripe
      stripe_customer = ensure_stripe_customer

      # Create invoice on Stripe
      stripe_invoice = create_stripe_invoice(stripe_customer)

      # Add line items
      add_line_items_to_stripe_invoice(stripe_invoice)

      # Finalize and send invoice
      finalized_invoice = Stripe::Invoice.finalize_invoice(
        stripe_invoice.id,
        { auto_advance: true },
        { stripe_account: @merchant.merchant_processor.processor_id }
      )

      # Send the invoice
      Stripe::Invoice.send_invoice(
        finalized_invoice.id,
        {},
        { stripe_account: @merchant.merchant_processor.processor_id }
      )

      # Update local invoice with Stripe ID
      @invoice.update(stripe_invoice_id: finalized_invoice.id)

      {
        success: true,
        stripe_invoice: finalized_invoice
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to send invoice: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Void an invoice on Stripe
  def void_invoice
    return { success: true } unless @invoice.stripe_invoice_id

    begin
      Stripe::Invoice.void_invoice(
        @invoice.stripe_invoice_id,
        {},
        { stripe_account: @merchant.merchant_processor.processor_id }
      )

      {
        success: true
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to void invoice: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Sync invoice status from Stripe
  def sync_invoice
    return { success: false, error: "No Stripe invoice ID" } unless @invoice.stripe_invoice_id

    begin
      stripe_invoice = Stripe::Invoice.retrieve(
        @invoice.stripe_invoice_id,
        { stripe_account: @merchant.merchant_processor.processor_id }
      )

      # Update invoice status based on Stripe status
      update_invoice_from_stripe(stripe_invoice)

      {
        success: true,
        stripe_invoice: stripe_invoice
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to sync invoice: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  private

  def validate_merchant!
    unless @merchant.merchant_onboarding_complete?
      raise InvoiceError, "Merchant must complete Stripe Connect onboarding"
    end

    unless @merchant.on_trial_or_subscribed?
      raise InvoiceError, "Merchant must have an active subscription"
    end
  end

  # Ensure customer exists on Stripe connected account
  def ensure_stripe_customer
    if @customer.stripe_customer_id
      # Customer already exists, retrieve it
      Stripe::Customer.retrieve(
        @customer.stripe_customer_id,
        { stripe_account: @merchant.merchant_processor.processor_id }
      )
    else
      # Create customer on connected account
      stripe_customer = Stripe::Customer.create(
        {
          name: @customer.name,
          email: @customer.email,
          phone: @customer.phone,
          address: {
            line1: @customer.address_line1,
            line2: @customer.address_line2,
            city: @customer.city,
            state: @customer.state,
            postal_code: @customer.postal_code,
            country: @customer.country
          }.compact,
          metadata: {
            merchant_customer_id: @customer.id
          }
        },
        { stripe_account: @merchant.merchant_processor.processor_id }
      )

      # Save Stripe customer ID
      @customer.update(stripe_customer_id: stripe_customer.id)

      stripe_customer
    end
  end

  # Create invoice on Stripe
  def create_stripe_invoice(stripe_customer)
    Stripe::Invoice.create(
      {
        customer: stripe_customer.id,
        collection_method: "send_invoice",
        days_until_due: @invoice.days_until_due,
        description: @invoice.notes,
        footer: @invoice.footer_text,
        application_fee_amount: @invoice.application_fee_cents,
        on_behalf_of: @merchant.merchant_processor.processor_id,
        metadata: {
          merchant_invoice_id: @invoice.id,
          invoice_number: @invoice.invoice_number
        }
      },
      { stripe_account: @merchant.merchant_processor.processor_id }
    )
  end

  # Add line items to Stripe invoice
  def add_line_items_to_stripe_invoice(stripe_invoice)
    @invoice.invoice_items.each do |item|
      Stripe::InvoiceItem.create(
        {
          customer: stripe_invoice.customer,
          invoice: stripe_invoice.id,
          description: item.description,
          quantity: item.quantity.to_i,
          unit_amount: item.unit_price_cents,
          currency: "usd",
          metadata: {
            merchant_invoice_item_id: item.id
          }
        },
        { stripe_account: @merchant.merchant_processor.processor_id }
      )
    end
  end

  # Update local invoice from Stripe invoice data
  def update_invoice_from_stripe(stripe_invoice)
    status_map = {
      "draft" => "draft",
      "open" => "open",
      "paid" => "paid",
      "void" => "void",
      "uncollectible" => "uncollectible"
    }

    updates = {
      status: status_map[stripe_invoice.status] || @invoice.status,
      subtotal_cents: stripe_invoice.subtotal,
      tax_cents: stripe_invoice.tax || 0,
      total_cents: stripe_invoice.total
    }

    updates[:paid_at] = Time.at(stripe_invoice.status_transitions.paid_at) if stripe_invoice.status == "paid"
    updates[:voided_at] = Time.at(stripe_invoice.status_transitions.voided_at) if stripe_invoice.status == "void"

    @invoice.update(updates)
  end
end
