# Pay webhook configuration for referral rewards
Rails.application.config.to_prepare do
  # Listen for subscription payment events to award referral credits
  Pay::Webhooks.delegator.subscribe "stripe.invoice.payment_succeeded" do |event|
    ReferralRewardWebhookJob.perform_later(event)
  end

  # Listen for subscription updates to handle trial end
  Pay::Webhooks.delegator.subscribe "stripe.customer.subscription.updated" do |event|
    subscription_data = event.data["object"]

    # Check if trial just ended and subscription became active
    if subscription_data["status"] == "active" &&
       subscription_data["trial_end"].present? &&
       Time.at(subscription_data["trial_end"]) < Time.current

      ReferralRewardWebhookJob.perform_later(event)
    end
  end

  # Listen for invoice creation to apply available credits
  Pay::Webhooks.delegator.subscribe "stripe.invoice.created" do |event|
    CreditApplicationWebhookJob.perform_later(event)
  end

  # Connect invoice webhooks for merchant invoicing
  # These events come from connected accounts
  Pay::Webhooks.delegator.subscribe "stripe.invoice.paid" do |event|
    MerchantInvoiceWebhookJob.perform_later(event)
  end

  Pay::Webhooks.delegator.subscribe "stripe.invoice.payment_failed" do |event|
    MerchantInvoiceWebhookJob.perform_later(event)
  end

  Pay::Webhooks.delegator.subscribe "stripe.invoice.voided" do |event|
    MerchantInvoiceWebhookJob.perform_later(event)
  end

  Pay::Webhooks.delegator.subscribe "stripe.invoice.marked_uncollectible" do |event|
    MerchantInvoiceWebhookJob.perform_later(event)
  end
end
