require "test_helper"

class ReferralTest < ActiveSupport::TestCase
  def setup
    @referrer = users(:one)
    @referee = users(:two)
  end

  test "user has referral associations" do
    assert_respond_to @referrer, :referral_codes
    assert_respond_to @referrer, :referrals
    assert_respond_to @referee, :referral
  end

  test "can create referral code" do
    referral_code = @referrer.referral_codes.create
    assert referral_code.persisted?
    assert referral_code.code.present?
  end

  test "refer method works" do
    referral_code = @referrer.referral_codes.create

    # Simulate what the refer method should do
    result = Refer.refer(code: referral_code.code, referee: @referee)

    # Check that a referral was created
    referral = @referrer.referrals.find_by(referee: @referee)
    assert referral.present?, "Referral should have been created"
    assert_equal @referee, referral.referee
    assert_equal @referrer, referral.referrer
  end

  test "does not create duplicate referrals" do
    referral_code = @referrer.referral_codes.create

    # Create first referral
    Refer.refer(code: referral_code.code, referee: @referee)
    initial_count = @referrer.referrals.count

    # Try to create second referral for same referee
    Refer.refer(code: referral_code.code, referee: @referee)

    # Count should not increase
    assert_equal initial_count, @referrer.referrals.count
  end
end
