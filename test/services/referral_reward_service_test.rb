require "test_helper"

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

    # Mock subscription and related objects
    @subscription = mock_subscription
    @customer = mock_customer(@referee)
    @charge = mock_charge(2900) # $29.00

    # Set up configuration
    @config = ReferralConfiguration.create!(
      reward_percentage: 10.0,
      enabled: true,
      name: "Test Config"
    )
  end

  test "should create reward when eligible" do
    mock_subscription_methods

    assert_difference "ReferralReward.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        ReferralRewardService.process_subscription_payment(@subscription)
      end
    end

    reward = ReferralReward.last
    assert_equal @referrer, reward.referrer
    assert_equal @referee, reward.referee
    assert_equal 290, reward.amount # 10% of $29.00
    assert_equal "available", reward.status
  end

  test "should not create reward when already exists for subscription" do
    mock_subscription_methods

    # Create existing reward
    ReferralReward.create!(
      referrer: @referrer,
      referee: @referee,
      subscription_id: @subscription.processor_id,
      amount: 100,
      status: "available",
      earned_at: Time.current
    )

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(@subscription)
    end
  end

  test "should not create reward when no referral exists" do
    mock_subscription_methods
    @referral.destroy

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(@subscription)
    end
  end

  test "should not create reward when subscription has no trial" do
    @subscription.stubs(:trial_ends_at).returns(nil)
    mock_other_subscription_methods

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(@subscription)
    end
  end

  test "should not create reward when trial has not ended" do
    @subscription.stubs(:trial_ends_at).returns(1.week.from_now)
    mock_other_subscription_methods

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(@subscription)
    end
  end

  test "should not create reward when subscription is not active" do
    @subscription.stubs(:active?).returns(false)
    mock_other_subscription_methods

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(@subscription)
    end
  end

  test "should not create reward when configuration is disabled" do
    @config.update!(enabled: false)
    mock_subscription_methods

    assert_no_difference "ReferralReward.count" do
      ReferralRewardService.process_subscription_payment(@subscription)
    end
  end

  test "should handle max_credits_per_referral limit" do
    @config.update!(max_credits_per_referral: 100) # $1.00 limit
    mock_subscription_methods

    ReferralRewardService.process_subscription_payment(@subscription)

    reward = ReferralReward.last
    assert_equal 100, reward.amount # Limited to $1.00 instead of $2.90
  end

  private

  def mock_subscription
    subscription = mock("subscription")
    subscription.stubs(:processor_id).returns("sub_test123")
    subscription.stubs(:customer).returns(@customer)
    subscription
  end

  def mock_customer(user)
    customer = mock("customer")
    customer.stubs(:owner).returns(user)
    customer
  end

  def mock_charge(amount_cents)
    charge = mock("charge")
    charge.stubs(:amount).returns(amount_cents)
    charge
  end

  def mock_subscription_methods
    @subscription.stubs(:trial_ends_at).returns(1.week.ago)
    @subscription.stubs(:active?).returns(true)

    charges_relation = mock("charges")
    charges_relation.stubs(:order).with(created_at: :desc).returns(charges_relation)
    charges_relation.stubs(:first).returns(@charge)
    @subscription.stubs(:charges).returns(charges_relation)

    # Mock existing reward check
    ReferralReward.stubs(:exists?).with(subscription_id: @subscription.processor_id).returns(false)
  end

  def mock_other_subscription_methods
    @subscription.stubs(:active?).returns(true)

    charges_relation = mock("charges")
    charges_relation.stubs(:order).with(created_at: :desc).returns(charges_relation)
    charges_relation.stubs(:first).returns(@charge)
    @subscription.stubs(:charges).returns(charges_relation)

    ReferralReward.stubs(:exists?).with(subscription_id: @subscription.processor_id).returns(false)
  end
end
