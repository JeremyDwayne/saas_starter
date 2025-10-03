require "test_helper"

class CustomPlatformFeeTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @custom_fee = CustomPlatformFee.new(
      user: @user,
      fee_percentage: 3.5,
      notes: "Negotiated rate for large customer"
    )
  end

  test "should be valid with valid attributes" do
    assert @custom_fee.valid?
  end

  test "should require user" do
    @custom_fee.user = nil
    assert_not @custom_fee.valid?
    assert_includes @custom_fee.errors[:user], "must exist"
  end

  test "should require fee_percentage" do
    @custom_fee.fee_percentage = nil
    assert_not @custom_fee.valid?
    assert_includes @custom_fee.errors[:fee_percentage], "can't be blank"
  end

  test "should validate fee_percentage is greater than 0" do
    @custom_fee.fee_percentage = 0
    assert_not @custom_fee.valid?
    assert_includes @custom_fee.errors[:fee_percentage], "must be greater than 0"
  end

  test "should validate fee_percentage is less than or equal to 100" do
    @custom_fee.fee_percentage = 101
    assert_not @custom_fee.valid?
    assert_includes @custom_fee.errors[:fee_percentage], "must be less than or equal to 100"
  end

  test "should validate minimum_fee_cents is greater than 0 when present" do
    @custom_fee.minimum_fee_cents = 0
    assert_not @custom_fee.valid?
    assert_includes @custom_fee.errors[:minimum_fee_cents], "must be greater than 0"
  end

  test "should allow nil minimum_fee_cents" do
    @custom_fee.minimum_fee_cents = nil
    assert @custom_fee.valid?
  end

  test "should validate user_id uniqueness" do
    @custom_fee.save!
    duplicate = CustomPlatformFee.new(
      user: @user,
      fee_percentage: 2.0
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "active scope should return only non-expired fees" do
    active_fee = CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 3.0,
      expires_at: Date.tomorrow
    )

    user_two = users(:two)
    expired_fee = CustomPlatformFee.create!(
      user: user_two,
      fee_percentage: 2.0,
      expires_at: Date.yesterday
    )

    assert_includes CustomPlatformFee.active, active_fee
    assert_not_includes CustomPlatformFee.active, expired_fee
  end

  test "active scope should include fees with no expiration" do
    permanent_fee = CustomPlatformFee.create!(
      user: @user,
      fee_percentage: 4.0,
      expires_at: nil
    )

    assert_includes CustomPlatformFee.active, permanent_fee
  end

  test "active? should return true when not expired" do
    @custom_fee.expires_at = Date.tomorrow
    assert @custom_fee.active?
  end

  test "active? should return false when expired" do
    @custom_fee.expires_at = Date.yesterday
    assert_not @custom_fee.active?
  end

  test "active? should return true when expires_at is nil" do
    @custom_fee.expires_at = nil
    assert @custom_fee.active?
  end

  test "calculate_application_fee should calculate percentage correctly" do
    @custom_fee.fee_percentage = 3.5
    fee = @custom_fee.calculate_application_fee(10000) # $100.00
    assert_equal 350, fee # $3.50
  end

  test "calculate_application_fee should round to nearest cent" do
    @custom_fee.fee_percentage = 2.33
    fee = @custom_fee.calculate_application_fee(10000)
    assert_equal 233, fee # Rounds 233.3 to 233
  end

  test "calculate_application_fee should enforce minimum fee when set" do
    @custom_fee.fee_percentage = 3.0
    @custom_fee.minimum_fee_cents = 500 # $5.00 minimum
    fee = @custom_fee.calculate_application_fee(100) # $1.00 charge
    assert_equal 500, fee # Should use minimum instead of 3 cents
  end

  test "calculate_application_fee should use calculated fee when above minimum" do
    @custom_fee.fee_percentage = 5.0
    @custom_fee.minimum_fee_cents = 100
    fee = @custom_fee.calculate_application_fee(10000) # $100.00 charge
    assert_equal 500, fee # $5.00 > $1.00 minimum
  end

  test "calculate_application_fee should work without minimum fee" do
    @custom_fee.fee_percentage = 4.0
    @custom_fee.minimum_fee_cents = nil
    fee = @custom_fee.calculate_application_fee(1000)
    assert_equal 40, fee
  end

  test "fee_percentage_display should format percentage correctly" do
    @custom_fee.fee_percentage = 3.75
    assert_equal "3.75%", @custom_fee.fee_percentage_display
  end

  test "should allow optional notes" do
    @custom_fee.notes = nil
    assert @custom_fee.valid?

    @custom_fee.notes = "Special rate for valued customer"
    assert @custom_fee.valid?
  end

  test "should allow optional expires_at" do
    @custom_fee.expires_at = nil
    assert @custom_fee.valid?

    @custom_fee.expires_at = Date.today + 1.year
    assert @custom_fee.valid?
  end
end
