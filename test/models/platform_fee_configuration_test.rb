require "test_helper"

class PlatformFeeConfigurationTest < ActiveSupport::TestCase
  def setup
    @config = PlatformFeeConfiguration.new(
      subscription_tier: "personal",
      fee_percentage: 5.0,
      active: true
    )
  end

  test "should be valid with valid attributes" do
    assert @config.valid?
  end

  test "should require subscription_tier" do
    @config.subscription_tier = nil
    assert_not @config.valid?
    assert_includes @config.errors[:subscription_tier], "can't be blank"
  end

  test "should require fee_percentage" do
    @config.fee_percentage = nil
    assert_not @config.valid?
    assert_includes @config.errors[:fee_percentage], "can't be blank"
  end

  test "should validate fee_percentage is greater than 0" do
    @config.fee_percentage = 0
    assert_not @config.valid?
    assert_includes @config.errors[:fee_percentage], "must be greater than 0"
  end

  test "should validate fee_percentage is less than or equal to 100" do
    @config.fee_percentage = 101
    assert_not @config.valid?
    assert_includes @config.errors[:fee_percentage], "must be less than or equal to 100"
  end

  test "should validate minimum_fee_cents is greater than 0 when present" do
    @config.minimum_fee_cents = 0
    assert_not @config.valid?
    assert_includes @config.errors[:minimum_fee_cents], "must be greater than 0"
  end

  test "should allow nil minimum_fee_cents" do
    @config.minimum_fee_cents = nil
    assert @config.valid?
  end

  test "should validate subscription_tier is in VALID_TIERS" do
    @config.subscription_tier = "invalid_tier"
    assert_not @config.valid?
    assert_includes @config.errors[:subscription_tier], "is not included in the list"
  end

  test "should validate subscription_tier uniqueness" do
    @config.save!
    duplicate = PlatformFeeConfiguration.new(
      subscription_tier: "personal",
      fee_percentage: 3.0
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:subscription_tier], "has already been taken"
  end

  test "VALID_TIERS should contain expected tiers" do
    assert_equal %w[personal professional enterprise none], PlatformFeeConfiguration::VALID_TIERS
  end

  test "active scope should return only active configurations" do
    active_config = PlatformFeeConfiguration.create!(
      subscription_tier: "personal",
      fee_percentage: 5.0,
      active: true
    )
    inactive_config = PlatformFeeConfiguration.create!(
      subscription_tier: "professional",
      fee_percentage: 3.0,
      active: false
    )

    assert_includes PlatformFeeConfiguration.active, active_config
    assert_not_includes PlatformFeeConfiguration.active, inactive_config
  end

  test "fee_for_tier should find active configuration by tier" do
    config = PlatformFeeConfiguration.create!(
      subscription_tier: "professional",
      fee_percentage: 3.0,
      active: true
    )

    found = PlatformFeeConfiguration.fee_for_tier("professional")
    assert_equal config, found
  end

  test "fee_for_tier should handle symbol input" do
    config = PlatformFeeConfiguration.create!(
      subscription_tier: "enterprise",
      fee_percentage: 2.0,
      active: true
    )

    found = PlatformFeeConfiguration.fee_for_tier(:enterprise)
    assert_equal config, found
  end

  test "fee_for_tier should return nil for non-existent tier" do
    assert_nil PlatformFeeConfiguration.fee_for_tier("nonexistent")
  end

  test "fee_for_tier should ignore inactive configurations" do
    PlatformFeeConfiguration.create!(
      subscription_tier: "personal",
      fee_percentage: 5.0,
      active: false
    )

    assert_nil PlatformFeeConfiguration.fee_for_tier("personal")
  end

  test "calculate_application_fee should calculate percentage correctly" do
    @config.fee_percentage = 5.0
    fee = @config.calculate_application_fee(10000) # $100.00
    assert_equal 500, fee # $5.00
  end

  test "calculate_application_fee should round to nearest cent" do
    @config.fee_percentage = 3.33
    fee = @config.calculate_application_fee(10000)
    assert_equal 333, fee # Rounds 333.3 to 333
  end

  test "calculate_application_fee should enforce minimum fee when set" do
    @config.fee_percentage = 5.0
    @config.minimum_fee_cents = 500 # $5.00 minimum
    fee = @config.calculate_application_fee(100) # $1.00 charge
    assert_equal 500, fee # Should use minimum instead of 5 cents
  end

  test "calculate_application_fee should use calculated fee when above minimum" do
    @config.fee_percentage = 5.0
    @config.minimum_fee_cents = 100
    fee = @config.calculate_application_fee(10000) # $100.00 charge
    assert_equal 500, fee # $5.00 > $1.00 minimum
  end

  test "calculate_application_fee should work without minimum fee" do
    @config.fee_percentage = 3.0
    @config.minimum_fee_cents = nil
    fee = @config.calculate_application_fee(1000)
    assert_equal 30, fee
  end

  test "fee_percentage_display should format percentage correctly" do
    @config.fee_percentage = 5.5
    assert_equal "5.5%", @config.fee_percentage_display
  end

  test "should default active to true" do
    config = PlatformFeeConfiguration.new(
      subscription_tier: "personal",
      fee_percentage: 5.0
    )
    assert config.active
  end
end
