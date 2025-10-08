require "test_helper"

class ReferralRewardMailerTest < ActionMailer::TestCase
  def setup
    @referrer = users(:one)
    @referee = users(:two)
    @reward = ReferralReward.create!(
      referrer: @referrer,
      referee: @referee,
      subscription_id: "sub_test123",
      amount: 1000, # $10.00
      status: "available",
      earned_at: Time.current
    )
  end

  test "credit_earned should send email with correct details" do
    mail = ReferralRewardMailer.credit_earned(@reward)

    assert_equal "🎉 You've earned $10.00 in referral credits!", mail.subject
    assert_equal [ @referrer.email ], mail.to
    assert_match @referrer.name || @referrer.email.split("@").first, mail.body.encoded
    assert_match "$10.00", mail.body.encoded
    # Template shows name if available, otherwise email
    assert_match(@referee.name || @referee.email, mail.body.encoded)
    assert_match "Available for use", mail.body.encoded
  end

  test "credit_earned should include referral dashboard link" do
    mail = ReferralRewardMailer.credit_earned(@reward)

    assert_match "/settings", mail.body.encoded
    assert_match "View My Referral Dashboard", mail.body.encoded
  end
end
