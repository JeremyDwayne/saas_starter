require "test_helper"

class OnboardingTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @organization = organizations(:one)
    # Use fixture instead of creating new one
    @onboarding = onboardings(:one)
  end

  test "should be valid with required attributes" do
    assert @onboarding.valid?
  end

  test "should belong to organization" do
    assert_respond_to @onboarding, :organization
    assert_equal @organization, @onboarding.organization
  end

  test "should have default values" do
    new_onboarding = Onboarding.new(organization: @organization)
    assert_equal false, new_onboarding.profile_completed
    assert_equal false, new_onboarding.organization_details_completed
    assert_equal false, new_onboarding.platform_configured
    assert_equal false, new_onboarding.stripe_connect_completed
    assert_equal 0, new_onboarding.current_step
  end

  test "should require organization" do
    onboarding = Onboarding.new
    assert_not onboarding.valid?
    assert_includes onboarding.errors[:organization_id], "can't be blank"
  end

  test "should enforce unique organization" do
    duplicate = Onboarding.new(organization: @organization)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:organization_id], "has already been taken"
  end

  test "should not be complete initially" do
    assert_not @onboarding.complete?
  end

  test "should be complete when all steps are done" do
    @onboarding.update!(
      profile_completed: true,
      organization_details_completed: true,
      platform_configured: true,
      stripe_connect_completed: true
    )
    assert @onboarding.complete?
  end

  test "should calculate progress percentage correctly" do
    assert_equal 0, @onboarding.progress_percentage

    @onboarding.update!(profile_completed: true)
    assert_equal 25, @onboarding.progress_percentage

    @onboarding.update!(organization_details_completed: true)
    assert_equal 50, @onboarding.progress_percentage

    @onboarding.update!(platform_configured: true)
    assert_equal 75, @onboarding.progress_percentage

    @onboarding.update!(stripe_connect_completed: true)
    assert_equal 100, @onboarding.progress_percentage
  end

  test "should return current step name" do
    assert_equal :profile, @onboarding.current_step_name

    @onboarding.update!(current_step: 1)
    assert_equal :organization_details, @onboarding.current_step_name

    @onboarding.update!(current_step: 2)
    assert_equal :platform_configuration, @onboarding.current_step_name

    @onboarding.update!(current_step: 3)
    assert_equal :stripe_connect, @onboarding.current_step_name
  end

  test "should check if step is completed" do
    assert_not @onboarding.step_completed?(:profile)

    @onboarding.update!(profile_completed: true)
    assert @onboarding.step_completed?(:profile)
    assert_not @onboarding.step_completed?(:organization_details)
  end

  test "should complete individual steps" do
    @onboarding.complete_step!(:profile)
    assert @onboarding.profile_completed?

    @onboarding.complete_step!(:organization_details)
    assert @onboarding.organization_details_completed?

    @onboarding.complete_step!(:platform_configuration)
    assert @onboarding.platform_configured?

    @onboarding.complete_step!(:stripe_connect)
    assert @onboarding.stripe_connect_completed?
  end

  test "should set completed_at when all steps are complete" do
    assert_nil @onboarding.completed_at

    @onboarding.complete_step!(:profile)
    @onboarding.complete_step!(:organization_details)
    @onboarding.complete_step!(:platform_configuration)

    assert_nil @onboarding.completed_at

    @onboarding.complete_step!(:stripe_connect)
    assert_not_nil @onboarding.completed_at
  end

  test "should advance to next step" do
    assert_equal 0, @onboarding.current_step

    @onboarding.advance_step!
    assert_equal 1, @onboarding.current_step

    @onboarding.advance_step!
    assert_equal 2, @onboarding.current_step

    @onboarding.advance_step!
    assert_equal 3, @onboarding.current_step

    # Should not advance beyond step 3
    @onboarding.advance_step!
    assert_equal 3, @onboarding.current_step
  end

  test "should go to specific step" do
    @onboarding.go_to_step!(2)
    assert_equal 2, @onboarding.current_step

    @onboarding.go_to_step!(0)
    assert_equal 0, @onboarding.current_step

    # Should not change for invalid step
    @onboarding.go_to_step!(10)
    assert_equal 0, @onboarding.current_step
  end

  test "should return steps with status" do
    steps = @onboarding.steps_with_status

    assert_equal 4, steps.length
    assert_equal 0, steps[0][:index]
    assert_equal :profile, steps[0][:name]
    assert_not steps[0][:completed]
    assert steps[0][:current]

    @onboarding.update!(profile_completed: true, current_step: 1)
    steps = @onboarding.steps_with_status

    assert steps[0][:completed]
    assert_not steps[0][:current]
    assert_not steps[1][:completed]
    assert steps[1][:current]
  end

  test "should validate current_step is within range" do
    @onboarding.current_step = -1
    assert_not @onboarding.valid?

    @onboarding.current_step = 5
    assert_not @onboarding.valid?

    @onboarding.current_step = 2
    assert @onboarding.valid?
  end
end
