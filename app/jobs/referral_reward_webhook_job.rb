class ReferralRewardWebhookJob < ApplicationJob
  queue_as :default

  def perform(event)
    Rails.logger.info "Processing referral reward webhook: #{event.type}"

    case event.type
    when "stripe.invoice.payment_succeeded"
      handle_payment_succeeded(event)
    when "stripe.customer.subscription.updated"
      handle_subscription_updated(event)
    else
      Rails.logger.warn "Unknown event type: #{event.type}"
    end
  rescue => e
    Rails.logger.error "Failed to process referral reward webhook: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def handle_payment_succeeded(event)
    invoice_data = event.data["object"]
    subscription_id = invoice_data["subscription"]

    return unless subscription_id

    subscription = find_subscription(subscription_id)
    return unless subscription

    Rails.logger.info "Processing payment for subscription: #{subscription_id}"
    ReferralRewardService.process_subscription_payment(subscription)
  end

  def handle_subscription_updated(event)
    subscription_data = event.data["object"]
    subscription_id = subscription_data["id"]

    subscription = find_subscription(subscription_id)
    return unless subscription

    Rails.logger.info "Processing subscription update for: #{subscription_id}"
    ReferralRewardService.process_subscription_payment(subscription)
  end

  def find_subscription(processor_id)
    Pay::Subscription.find_by(processor_id: processor_id)
  end
end
