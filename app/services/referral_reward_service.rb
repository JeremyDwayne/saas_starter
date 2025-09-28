class ReferralRewardService
  def self.process_subscription_payment(subscription)
    new(subscription).process_payment
  end

  def initialize(subscription)
    @subscription = subscription
    @customer = subscription.customer
    @user = @customer.owner
  end

  def process_payment
    return unless eligible_for_reward?

    referral = find_referral
    return unless referral

    config = ReferralConfiguration.current
    return unless config&.enabled?

    create_referral_reward(referral, config)
  end

  private

  attr_reader :subscription, :customer, :user

  def eligible_for_reward?
    # Check if this is the first payment after trial
    return false unless subscription.trial_ends_at.present?
    return false unless subscription.trial_ends_at < Time.current

    # Check if we've already rewarded for this subscription
    return false if ReferralReward.exists?(subscription_id: subscription.processor_id)

    # Check if subscription is active
    subscription.active?
  end

  def find_referral
    # Find the referral record for this user
    Refer::Referral.find_by(referee: user)
  end

  def create_referral_reward(referral, config)
    # Get the latest charge amount for this subscription
    latest_charge = subscription.charges.order(created_at: :desc).first
    return unless latest_charge

    reward_amount = config.calculate_reward_amount(latest_charge.amount)
    return if reward_amount <= 0

    reward = ReferralReward.create!(
      referrer: referral.referrer,
      referee: user,
      subscription_id: subscription.processor_id,
      amount: reward_amount,
      status: "available",
      earned_at: Time.current,
      notes: "Earned from #{user.email} subscription payment (#{latest_charge.amount / 100.0} USD)"
    )

    # Send email notification
    ReferralRewardMailer.credit_earned(reward).deliver_later

    Rails.logger.info "Created referral reward: #{reward.id} for #{reward.amount} cents and sent email notification"
    reward
  rescue => e
    Rails.logger.error "Failed to create referral reward: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end
end
