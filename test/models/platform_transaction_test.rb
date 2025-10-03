require "test_helper"

class PlatformTransactionTest < ActiveSupport::TestCase
  def setup
    @merchant = users(:one)
    @transaction = PlatformTransaction.new(
      merchant: @merchant,
      stripe_charge_id: "ch_test_12345",
      charge_amount_cents: 10000,
      application_fee_cents: 500,
      fee_percentage_applied: 5.0,
      customer_email: "customer@example.com",
      description: "Test charge",
      status: "succeeded"
    )
  end

  test "should be valid with valid attributes" do
    assert @transaction.valid?
  end

  test "should require merchant" do
    @transaction.merchant = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:merchant], "must exist"
  end

  test "should require stripe_charge_id" do
    @transaction.stripe_charge_id = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:stripe_charge_id], "can't be blank"
  end

  test "should validate stripe_charge_id uniqueness" do
    @transaction.save!
    duplicate = PlatformTransaction.new(
      merchant: users(:two),
      stripe_charge_id: "ch_test_12345",
      charge_amount_cents: 5000,
      application_fee_cents: 250,
      fee_percentage_applied: 5.0,
      status: "succeeded"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:stripe_charge_id], "has already been taken"
  end

  test "should require charge_amount_cents" do
    @transaction.charge_amount_cents = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:charge_amount_cents], "can't be blank"
  end

  test "should validate charge_amount_cents is greater than 0" do
    @transaction.charge_amount_cents = 0
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:charge_amount_cents], "must be greater than 0"
  end

  test "should require application_fee_cents" do
    @transaction.application_fee_cents = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:application_fee_cents], "can't be blank"
  end

  test "should validate application_fee_cents is greater than or equal to 0" do
    @transaction.application_fee_cents = -1
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:application_fee_cents], "must be greater than or equal to 0"
  end

  test "should allow zero application_fee_cents" do
    @transaction.application_fee_cents = 0
    assert @transaction.valid?
  end

  test "should require fee_percentage_applied" do
    @transaction.fee_percentage_applied = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:fee_percentage_applied], "can't be blank"
  end

  test "should require status" do
    @transaction.status = nil
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:status], "can't be blank"
  end

  test "should validate status is in allowed values" do
    @transaction.status = "invalid_status"
    assert_not @transaction.valid?
    assert_includes @transaction.errors[:status], "is not included in the list"
  end

  test "should allow succeeded status" do
    @transaction.status = "succeeded"
    assert @transaction.valid?
  end

  test "should allow refunded status" do
    @transaction.status = "refunded"
    assert @transaction.valid?
  end

  test "should allow partially_refunded status" do
    @transaction.status = "partially_refunded"
    assert @transaction.valid?
  end

  test "succeeded scope should return only succeeded transactions" do
    @transaction.save!

    refunded_transaction = PlatformTransaction.create!(
      merchant: @merchant,
      stripe_charge_id: "ch_test_67890",
      charge_amount_cents: 5000,
      application_fee_cents: 250,
      fee_percentage_applied: 5.0,
      status: "refunded"
    )

    assert_includes PlatformTransaction.succeeded, @transaction
    assert_not_includes PlatformTransaction.succeeded, refunded_transaction
  end

  test "refunded scope should return only refunded transactions" do
    succeeded_transaction = PlatformTransaction.create!(
      merchant: @merchant,
      stripe_charge_id: "ch_test_11111",
      charge_amount_cents: 10000,
      application_fee_cents: 500,
      fee_percentage_applied: 5.0,
      status: "succeeded"
    )

    refunded_transaction = PlatformTransaction.create!(
      merchant: @merchant,
      stripe_charge_id: "ch_test_22222",
      charge_amount_cents: 5000,
      application_fee_cents: 250,
      fee_percentage_applied: 5.0,
      status: "refunded"
    )

    assert_includes PlatformTransaction.refunded, refunded_transaction
    assert_not_includes PlatformTransaction.refunded, succeeded_transaction
  end

  test "for_merchant scope should return transactions for specific merchant" do
    merchant_two = users(:two)

    @transaction.save!

    other_transaction = PlatformTransaction.create!(
      merchant: merchant_two,
      stripe_charge_id: "ch_test_other",
      charge_amount_cents: 3000,
      application_fee_cents: 150,
      fee_percentage_applied: 5.0,
      status: "succeeded"
    )

    merchant_transactions = PlatformTransaction.for_merchant(@merchant.id)

    assert_includes merchant_transactions, @transaction
    assert_not_includes merchant_transactions, other_transaction
  end

  test "recent scope should order by created_at desc" do
    first_transaction = PlatformTransaction.create!(
      merchant: @merchant,
      stripe_charge_id: "ch_test_first",
      charge_amount_cents: 1000,
      application_fee_cents: 50,
      fee_percentage_applied: 5.0,
      status: "succeeded",
      created_at: 2.days.ago
    )

    second_transaction = PlatformTransaction.create!(
      merchant: @merchant,
      stripe_charge_id: "ch_test_second",
      charge_amount_cents: 2000,
      application_fee_cents: 100,
      fee_percentage_applied: 5.0,
      status: "succeeded",
      created_at: 1.day.ago
    )

    recent_transactions = PlatformTransaction.recent.to_a

    assert_equal second_transaction.id, recent_transactions.first.id
    assert_equal first_transaction.id, recent_transactions.last.id
  end

  test "charge_amount_dollars should convert cents to dollars" do
    @transaction.charge_amount_cents = 10000
    assert_equal 100.0, @transaction.charge_amount_dollars
  end

  test "application_fee_dollars should convert cents to dollars" do
    @transaction.application_fee_cents = 500
    assert_equal 5.0, @transaction.application_fee_dollars
  end

  test "net_amount_cents should calculate net amount correctly" do
    @transaction.charge_amount_cents = 10000
    @transaction.application_fee_cents = 500
    assert_equal 9500, @transaction.net_amount_cents
  end

  test "net_amount_dollars should convert net amount to dollars" do
    @transaction.charge_amount_cents = 10000
    @transaction.application_fee_cents = 500
    assert_equal 95.0, @transaction.net_amount_dollars
  end

  test "refunded? should return true when status is refunded" do
    @transaction.status = "refunded"
    assert @transaction.refunded?
  end

  test "refunded? should return false when status is not refunded" do
    @transaction.status = "succeeded"
    assert_not @transaction.refunded?
  end

  test "partially_refunded? should return true when status is partially_refunded" do
    @transaction.status = "partially_refunded"
    assert @transaction.partially_refunded?
  end

  test "partially_refunded? should return false when status is not partially_refunded" do
    @transaction.status = "succeeded"
    assert_not @transaction.partially_refunded?
  end

  test "succeeded? should return true when status is succeeded" do
    @transaction.status = "succeeded"
    assert @transaction.succeeded?
  end

  test "succeeded? should return false when status is not succeeded" do
    @transaction.status = "refunded"
    assert_not @transaction.succeeded?
  end

  test "should allow optional customer_email" do
    @transaction.customer_email = nil
    assert @transaction.valid?
  end

  test "should allow optional description" do
    @transaction.description = nil
    assert @transaction.valid?
  end

  test "should allow optional metadata" do
    @transaction.metadata = nil
    assert @transaction.valid?

    @transaction.metadata = { order_id: "12345", source: "mobile" }
    assert @transaction.valid?
  end

  test "should default status to succeeded" do
    transaction = PlatformTransaction.new(
      merchant: @merchant,
      stripe_charge_id: "ch_test_default",
      charge_amount_cents: 1000,
      application_fee_cents: 50,
      fee_percentage_applied: 5.0
    )
    assert_equal "succeeded", transaction.status
  end
end
