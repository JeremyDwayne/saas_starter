require "test_helper"

class ReferralConfigurationTest < ActiveSupport::TestCase
  def setup
    @config = ReferralConfiguration.create!(
      reward_percentage: 15.0,
      enabled: true,
      name: "Test Configuration"
    )
  end

  test "should be valid with valid attributes" do
    assert @config.valid?
  end

  test "should require reward_percentage" do
    @config.reward_percentage = nil
    assert_not @config.valid?
    assert_includes @config.errors[:reward_percentage], "can't be blank"
  end

  test "should require positive reward_percentage" do
    @config.reward_percentage = 0
    assert_not @config.valid?
    assert_includes @config.errors[:reward_percentage], "must be greater than 0"
  end

  test "should limit reward_percentage to 100" do
    @config.reward_percentage = 101
    assert_not @config.valid?
    assert_includes @config.errors[:reward_percentage], "must be less than or equal to 100"
  end

  test "should require name" do
    @config.name = nil
    assert_not @config.valid?
    assert_includes @config.errors[:name], "can't be blank"
  end

  test "should validate max_credits_per_referral is positive when present" do
    @config.max_credits_per_referral = -100
    assert_not @config.valid?
    assert_includes @config.errors[:max_credits_per_referral], "must be greater than 0"
  end

  test "should allow nil max_credits_per_referral" do
    @config.max_credits_per_referral = nil
    assert @config.valid?
  end

  test "should validate credit_expiry_days is positive when present" do
    @config.credit_expiry_days = -1
    assert_not @config.valid?
    assert_includes @config.errors[:credit_expiry_days], "must be greater than 0"
  end

  test "should allow nil credit_expiry_days" do
    @config.credit_expiry_days = nil
    assert @config.valid?
  end

  test "current should return enabled configuration" do
    # Disable any existing config
    ReferralConfiguration.update_all(enabled: false)

    # Create enabled config
    enabled_config = ReferralConfiguration.create!(
      reward_percentage: 20.0,
      enabled: true,
      name: "Current Config"
    )

    assert_equal enabled_config, ReferralConfiguration.current
  end

  test "current should return default when no enabled config exists" do
    # Disable all configs
    ReferralConfiguration.update_all(enabled: false)

    current = ReferralConfiguration.current
    assert_equal 10.0, current.reward_percentage
    assert current.enabled?
    assert_equal "Default Configuration", current.name
  end

  test "calculate_reward_amount should return correct percentage" do
    subscription_amount = 2900 # $29.00
    expected_reward = (2900 * 0.15).round # 15% of $29.00 = $4.35 = 435 cents

    assert_equal expected_reward, @config.calculate_reward_amount(subscription_amount)
  end

  test "calculate_reward_amount should apply max_credits_per_referral limit" do
    @config.update!(max_credits_per_referral: 200) # $2.00 limit
    subscription_amount = 2900 # $29.00, would normally earn $4.35

    assert_equal 200, @config.calculate_reward_amount(subscription_amount)
  end

  test "calculate_reward_amount should return 0 when disabled" do
    @config.update!(enabled: false)
    assert_equal 0, @config.calculate_reward_amount(2900)
  end

  test "credits_expire? should return true when credit_expiry_days is set" do
    @config.update!(credit_expiry_days: 30)
    assert @config.credits_expire?
  end

  test "credits_expire? should return false when credit_expiry_days is nil" do
    @config.update!(credit_expiry_days: nil)
    assert_not @config.credits_expire?
  end

  test "credit_expiry_date should return correct date when expiry is set" do
    @config.update!(credit_expiry_days: 30)
    from_date = Time.parse("2023-01-01")
    expected_date = from_date + 30.days

    assert_equal expected_date, @config.credit_expiry_date(from_date)
  end

  test "credit_expiry_date should return nil when no expiry is set" do
    @config.update!(credit_expiry_days: nil)
    assert_nil @config.credit_expiry_date
  end

  test "display methods should format correctly" do
    @config.update!(max_credits_per_referral: 500, credit_expiry_days: 90)

    assert_equal "15.0%", @config.reward_percentage_display
    assert_equal "$5.0", @config.max_credits_display
    assert_equal "90 days", @config.expiry_display
  end

  test "display methods should handle nil values" do
    @config.update!(max_credits_per_referral: nil, credit_expiry_days: nil)

    assert_equal "No limit", @config.max_credits_display
    assert_equal "No expiry", @config.expiry_display
  end
end
