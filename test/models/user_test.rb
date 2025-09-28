require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "available_credit_balance should sum available rewards" do
    user = User.create!(email_address: "test1@example.com", password: "password123")

    # Create some rewards
    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_1",
      amount: 500, # $5.00
      status: "available",
      earned_at: Time.current
    )

    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_2",
      amount: 300, # $3.00
      status: "available",
      earned_at: Time.current
    )

    # This one shouldn't count (used)
    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_3",
      amount: 200,
      status: "used",
      earned_at: Time.current
    )

    assert_equal 800, user.available_credit_balance
    assert_equal 8.0, user.available_credit_balance_dollars
  end

  test "total_earned_credits should sum all rewards" do
    user = User.create!(email_address: "test2@example.com", password: "password123")

    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_1",
      amount: 500,
      status: "available",
      earned_at: Time.current
    )

    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_2",
      amount: 300,
      status: "used",
      earned_at: Time.current
    )

    assert_equal 800, user.total_earned_credits
    assert_equal 8.0, user.total_earned_credits_dollars
  end

  test "total_used_credits should sum only used rewards" do
    user = User.create!(email_address: "test3@example.com", password: "password123")

    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_1",
      amount: 500,
      status: "available",
      earned_at: Time.current
    )

    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_2",
      amount: 300,
      status: "used",
      earned_at: Time.current
    )

    assert_equal 300, user.total_used_credits
    assert_equal 3.0, user.total_used_credits_dollars
  end

  test "successful_referrals_count should count non-pending rewards" do
    user = User.create!(email_address: "test4@example.com", password: "password123")

    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_1",
      amount: 500,
      status: "available",
      earned_at: Time.current
    )

    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_2",
      amount: 300,
      status: "used",
      earned_at: Time.current
    )

    # This one shouldn't count (pending)
    ReferralReward.create!(
      referrer: user,
      referee: users(:two),
      subscription_id: "sub_3",
      amount: 200,
      status: "pending",
      earned_at: Time.current
    )

    assert_equal 2, user.successful_referrals_count
  end
end
