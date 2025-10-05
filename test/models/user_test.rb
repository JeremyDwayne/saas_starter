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

  # Platform fee tests
  test "platform_fee_percentage should use custom fee when active" do
    user = User.create!(email_address: "test5@example.com", password: "password123")
    org = Organization.create!(owner: user, name: "Test Organization")

    CustomPlatformFee.create!(
      user: user,
      organization: org,
      fee_percentage: 2.5,
      expires_at: Date.tomorrow
    )

    assert_equal 2.5, user.platform_fee_percentage
  end

  test "platform_fee_percentage should fall back to tier fee when no custom fee" do
    user = User.create!(email_address: "test6@example.com", password: "password123")

    PlatformFeeConfiguration.create!(
      subscription_tier: "none",
      fee_percentage: 7.0,
      active: true
    )

    assert_equal 7.0, user.platform_fee_percentage
  end

  test "platform_fee_percentage should use default when no config exists" do
    user = User.create!(email_address: "test7@example.com", password: "password123")
    assert_equal 7.0, user.platform_fee_percentage
  end

  test "calculate_platform_fee should use custom fee calculation when active" do
    user = User.create!(email_address: "test8@example.com", password: "password123")
    org = Organization.create!(owner: user, name: "Test Organization")

    CustomPlatformFee.create!(
      user: user,
      organization: org,
      fee_percentage: 3.0
    )

    fee = user.calculate_platform_fee(10000) # $100
    assert_equal 300, fee # $3.00
  end

  test "calculate_platform_fee should use tier fee when no custom fee" do
    user = User.create!(email_address: "test9@example.com", password: "password123")

    PlatformFeeConfiguration.create!(
      subscription_tier: "none",
      fee_percentage: 5.0,
      active: true
    )

    fee = user.calculate_platform_fee(10000)
    assert_equal 500, fee
  end

  test "calculate_platform_fee should use default percentage when no config" do
    user = User.create!(email_address: "test10@example.com", password: "password123")

    fee = user.calculate_platform_fee(10000)
    assert_equal 700, fee # 7% default
  end

  test "current_subscription_tier should return none when no subscription" do
    user = User.create!(email_address: "test11@example.com", password: "password123")
    assert_equal "none", user.current_subscription_tier
  end

  test "merchant_onboarding_complete? should return false when no merchant processor" do
    user = User.create!(email_address: "test12@example.com", password: "password123")
    assert_not user.merchant_onboarding_complete?
  end

  test "can_accept_payments? should return false when not onboarded" do
    user = User.create!(email_address: "test13@example.com", password: "password123")
    assert_not user.can_accept_payments?
  end

  test "should have custom_platform_fee association" do
    user = User.create!(email_address: "test14@example.com", password: "password123")
    org = Organization.create!(owner: user, name: "Test Organization")

    custom_fee = CustomPlatformFee.create!(
      user: user,
      organization: org,
      fee_percentage: 3.5
    )

    assert_equal custom_fee, user.custom_platform_fee
  end

  test "should have platform_transactions association" do
    user = User.create!(email_address: "test15@example.com", password: "password123")
    org = Organization.create!(owner: user, name: "Test Organization")

    transaction = PlatformTransaction.create!(
      merchant: user,
      organization: org,
      stripe_charge_id: "ch_test_assoc",
      charge_amount_cents: 5000,
      application_fee_cents: 250,
      fee_percentage_applied: 5.0,
      status: "succeeded"
    )

    assert_includes user.platform_transactions, transaction
  end

  test "has many organizations through memberships" do
    user = User.create!(email_address: "test16@example.com", password: "password123")
    org1 = Organization.create!(name: "First Org", owner: user)
    org2 = Organization.create!(name: "Second Org", owner: user)

    OrganizationMembership.create!(user: user, organization: org1)
    OrganizationMembership.create!(user: user, organization: org2)

    assert_equal 2, user.organizations.count
    assert_includes user.organizations, org1
    assert_includes user.organizations, org2
  end

  test "destroys memberships when user is destroyed" do
    user = User.create!(email_address: "test17@example.com", password: "password123")
    org = Organization.create!(name: "Test Org", owner: user)
    OrganizationMembership.create!(user: user, organization: org)

    assert_difference "OrganizationMembership.count", -1 do
      user.destroy
    end
  end
end
