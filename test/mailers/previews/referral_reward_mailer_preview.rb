# Preview all emails at http://localhost:3000/rails/mailers/referral_reward_mailer
class ReferralRewardMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/referral_reward_mailer/credit_earned
  def credit_earned
    ReferralRewardMailer.credit_earned
  end
end
