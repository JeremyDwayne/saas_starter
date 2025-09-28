class ReferralRewardMailer < ApplicationMailer
  def credit_earned(referral_reward)
    @reward = referral_reward
    @referrer = @reward.referrer
    @referee = @reward.referee
    @credit_amount = @reward.amount_dollars

    mail(
      to: @referrer.email,
      subject: "🎉 You've earned $#{sprintf('%.2f', @credit_amount)} in referral credits!"
    )
  end
end
