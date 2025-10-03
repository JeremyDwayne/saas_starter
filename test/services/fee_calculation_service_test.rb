require "test_helper"

class FeeCalculationServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "calculate_for_user should return fee breakdown hash" do
    result = FeeCalculationService.calculate_for_user(@user, 10000)

    assert_kind_of Hash, result
    assert_includes result.keys, :amount_cents
    assert_includes result.keys, :fee_cents
    assert_includes result.keys, :fee_percentage
    assert_includes result.keys, :net_amount_cents
    assert_includes result.keys, :fee_source
  end

  test "should calculate with custom fee when present" do
    CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 3.5,
      expires_at: Date.tomorrow
    )

    result = FeeCalculationService.calculate_for_user(@user, 10000)

    assert_equal 10000, result[:amount_cents]
    assert_equal 350, result[:fee_cents] # 3.5% of 10000
    assert_equal 3.5, result[:fee_percentage]
    assert_equal 9650, result[:net_amount_cents]
    assert_equal "custom", result[:fee_source]
  end

  test "should calculate with tier fee when no custom fee" do
    PlatformFeeConfiguration.create!(
      subscription_tier: "none",
      fee_percentage: 5.0,
      active: true
    )

    result = FeeCalculationService.calculate_for_user(@user, 10000)

    assert_equal 10000, result[:amount_cents]
    assert_equal 500, result[:fee_cents]
    assert_equal 5.0, result[:fee_percentage]
    assert_equal 9500, result[:net_amount_cents]
    assert_equal "default", result[:fee_source]
  end

  test "should use default fee when no configuration exists" do
    result = FeeCalculationService.calculate_for_user(@user, 10000)

    assert_equal 10000, result[:amount_cents]
    assert_equal 700, result[:fee_cents] # 7% default
    assert_equal 7.0, result[:fee_percentage]
    assert_equal 9300, result[:net_amount_cents]
    assert_equal "default", result[:fee_source]
  end

  test "should calculate correctly for different amounts" do
    CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 4.0
    )

    # Test $50.00
    result = FeeCalculationService.calculate_for_user(@user, 5000)
    assert_equal 200, result[:fee_cents]
    assert_equal 4800, result[:net_amount_cents]

    # Test $200.00
    result = FeeCalculationService.calculate_for_user(@user, 20000)
    assert_equal 800, result[:fee_cents]
    assert_equal 19200, result[:net_amount_cents]
  end

  test "should respect minimum fee when set" do
    CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 3.0,
      minimum_fee_cents: 500 # $5.00 minimum
    )

    # Small charge should use minimum
    result = FeeCalculationService.calculate_for_user(@user, 1000) # $10.00
    assert_equal 500, result[:fee_cents] # Uses minimum instead of $0.30

    # Large charge should calculate normally
    result = FeeCalculationService.calculate_for_user(@user, 100000) # $1000.00
    assert_equal 3000, result[:fee_cents] # 3% = $30
  end

  test "should ignore expired custom fees" do
    PlatformFeeConfiguration.create!(
      subscription_tier: "none",
      fee_percentage: 5.0,
      active: true
    )

    CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 2.0,
      expires_at: Date.yesterday # Expired
    )

    result = FeeCalculationService.calculate_for_user(@user, 10000)

    # Should use tier fee, not expired custom fee
    assert_equal 500, result[:fee_cents]
    assert_equal "default", result[:fee_source]
  end

  test "should handle zero amount" do
    result = FeeCalculationService.calculate_for_user(@user, 0)

    assert_equal 0, result[:amount_cents]
    assert_equal 0, result[:fee_cents]
    assert_equal 0, result[:net_amount_cents]
  end

  test "should round fee calculations correctly" do
    CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 3.33
    )

    result = FeeCalculationService.calculate_for_user(@user, 10000)

    # 3.33% of $100 = $3.33 (333 cents)
    assert_equal 333, result[:fee_cents]
    assert_equal 9667, result[:net_amount_cents]
  end

  test "fee_source should be custom when active custom fee exists" do
    CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 2.5
    )

    result = FeeCalculationService.calculate_for_user(@user, 10000)
    assert_equal "custom", result[:fee_source]
  end

  test "fee_source should be default when no subscription and no custom fee" do
    result = FeeCalculationService.calculate_for_user(@user, 10000)
    assert_equal "default", result[:fee_source]
  end
end
