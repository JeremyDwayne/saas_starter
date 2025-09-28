require "test_helper"

class ReferralRewardTest < ActiveSupport::TestCase
  def setup
    @referrer = users(:one)
    @referee = users(:two)
    @reward = ReferralReward.create!(
      referrer: @referrer,
      referee: @referee,
      subscription_id: "sub_test123",
      amount: 1000, # $10.00
      status: "available",
      earned_at: Time.current
    )
  end

  test "should be valid with valid attributes" do
    assert @reward.valid?
  end

  test "should require referrer" do
    @reward.referrer = nil
    assert_not @reward.valid?
    assert_includes @reward.errors[:referrer], "must exist"
  end

  test "should require referee" do
    @reward.referee = nil
    assert_not @reward.valid?
    assert_includes @reward.errors[:referee], "must exist"
  end

  test "should require amount" do
    @reward.amount = nil
    assert_not @reward.valid?
    assert_includes @reward.errors[:amount], "can't be blank"
  end

  test "should require positive amount" do
    @reward.amount = 0
    assert_not @reward.valid?
    assert_includes @reward.errors[:amount], "must be greater than 0"
  end

  test "should require valid status" do
    @reward.status = "invalid"
    assert_not @reward.valid?
    assert_includes @reward.errors[:status], "is not included in the list"
  end

  test "should require subscription_id" do
    @reward.subscription_id = nil
    assert_not @reward.valid?
    assert_includes @reward.errors[:subscription_id], "can't be blank"
  end

  test "should require earned_at" do
    @reward.earned_at = nil
    assert_not @reward.valid?
    assert_includes @reward.errors[:earned_at], "can't be blank"
  end

  test "amount_dollars should convert cents to dollars" do
    assert_equal 10.0, @reward.amount_dollars
  end

  test "should scope available rewards" do
    available_reward = ReferralReward.create!(
      referrer: @referrer,
      referee: @referee,
      subscription_id: "sub_available",
      amount: 500,
      status: "available",
      earned_at: Time.current
    )

    used_reward = ReferralReward.create!(
      referrer: @referrer,
      referee: @referee,
      subscription_id: "sub_used",
      amount: 300,
      status: "used",
      earned_at: Time.current
    )

    available_rewards = ReferralReward.available
    assert_includes available_rewards, @reward
    assert_includes available_rewards, available_reward
    assert_not_includes available_rewards, used_reward
  end

  test "mark_as_available! should update status" do
    @reward.update!(status: "pending")
    @reward.mark_as_available!
    assert_equal "available", @reward.status
  end

  test "mark_as_used! should update status and used_at" do
    used_time = Time.current
    @reward.mark_as_used!(used_at: used_time, notes: "Applied to invoice")

    assert_equal "used", @reward.status
    assert_equal used_time.to_i, @reward.used_at.to_i
    assert_equal "Applied to invoice", @reward.notes
  end

  test "status predicate methods should work" do
    assert @reward.available?
    assert_not @reward.used?
    assert_not @reward.pending?
    assert_not @reward.expired?

    @reward.update!(status: "used")
    assert_not @reward.available?
    assert @reward.used?
  end
end
