require "test_helper"
require "ostruct"

class ReferralRewardServiceTest < ActiveSupport::TestCase
  def setup
    @referrer = users(:one)
    @referee = users(:two)

    # Create a referral
    @referral = Refer::Referral.create!(
      referrer: @referrer,
      referee: @referee,
      referral_code: @referrer.referral_codes.create
    )

    # Set up configuration
    @config = ReferralConfiguration.create!(
      reward_percentage: 10.0,
      enabled: true,
      name: "Test Config"
    )
  end

  test "should not create reward when no referral exists" do
    @referral.destroy

    subscription = create_mock_subscription

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(subscription)
    end
  end

  test "should not create reward when configuration is disabled" do
    @config.update!(enabled: false)

    subscription = create_mock_subscription

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(subscription)
    end
  end

  test "should not create reward when already exists for subscription" do
    subscription = create_mock_subscription

    # Create existing reward
    ReferralReward.create!(
      referrer: @referrer,
      referee: @referee,
      subscription_id: subscription.processor_id,
      amount: 100,
      status: "available",
      earned_at: Time.current
    )

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(subscription)
    end
  end

  test "should handle basic service functionality" do
    # Test the service can be instantiated and called
    subscription = create_mock_subscription

    # Just test it doesn't crash - the actual webhook integration would be tested in integration tests
    assert_nothing_raised do
      ReferralRewardService.process_subscription_payment(subscription)
    end
  end

  private

  # Create a simple object that responds to the methods the service expects
  def create_mock_subscription
    customer = OpenStruct.new(owner: @referee)

    charge = OpenStruct.new(amount: 2900)
    charges = OpenStruct.new
    charges.define_singleton_method(:order) { |_| charges }
    charges.define_singleton_method(:first) { charge }

    subscription = OpenStruct.new(
      processor_id: "sub_test123",
      customer: customer,
      trial_ends_at: 1.week.ago,
      charges: charges
    )

    subscription.define_singleton_method(:active?) { true }

    subscription
  end
end
