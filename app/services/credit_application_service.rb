class CreditApplicationService
  def self.apply_credits_to_invoice(invoice_id, user)
    new(invoice_id, user).apply_credits
  end

  def initialize(invoice_id, user)
    @invoice_id = invoice_id
    @user = user
  end

  def apply_credits
    return unless should_apply_credits?

    available_credits = user.available_credit_balance
    return if available_credits <= 0

    apply_credit_to_stripe_invoice(available_credits)
  end

  private

  attr_reader :invoice_id, :user

  def should_apply_credits?
    # Only apply to subscription invoices, not one-time payments
    invoice = Stripe::Invoice.retrieve(invoice_id)
    invoice.subscription.present?
  rescue Stripe::StripeError => e
    Rails.logger.error "Failed to retrieve invoice #{invoice_id}: #{e.message}"
    false
  end

  def apply_credit_to_stripe_invoice(credit_amount_cents)
    # Convert cents to negative amount (Stripe uses negative amounts for discounts)
    credit_amount = -credit_amount_cents

    begin
      # Add a line item to the invoice for the credit
      Stripe::InvoiceItem.create(
        customer: user.payment_processor.processor_id,
        invoice: invoice_id,
        amount: credit_amount,
        currency: "usd",
        description: "Referral Credit Applied",
        metadata: {
          referral_credit: true,
          user_id: user.id,
          applied_at: Time.current.iso8601
        }
      )

      # Mark the credits as used
      mark_credits_as_used(credit_amount_cents)

      Rails.logger.info "Applied #{credit_amount_cents} cents in referral credits to invoice #{invoice_id}"
      true
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to apply credit to invoice #{invoice_id}: #{e.message}"
      false
    end
  end

  def mark_credits_as_used(amount_used)
    remaining_amount = amount_used

    user.earned_rewards.available.order(:earned_at).each do |reward|
      break if remaining_amount <= 0

      if reward.amount <= remaining_amount
        # Use entire reward
        reward.mark_as_used!(
          used_at: Time.current,
          notes: "Applied to invoice #{invoice_id}"
        )
        remaining_amount -= reward.amount
      else
        # Partial use - we'd need to split the reward or track partial usage
        # For now, we'll use the entire reward if any amount is needed
        reward.mark_as_used!(
          used_at: Time.current,
          notes: "Applied to invoice #{invoice_id} (partial use: #{remaining_amount}/#{reward.amount} cents)"
        )
        remaining_amount = 0
      end
    end
  end
end
