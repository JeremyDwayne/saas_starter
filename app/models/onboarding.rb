# Onboarding model
# Tracks organization onboarding progress through critical setup steps
class Onboarding < ApplicationRecord
  belongs_to :organization

  # Validations
  validates :organization_id, presence: true, uniqueness: true
  validates :current_step, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }

  # Step definitions
  STEPS = {
    0 => :profile,
    1 => :organization_details,
    2 => :platform_configuration,
    3 => :stripe_connect
  }.freeze

  STEP_NAMES = {
    profile: "Complete Your Profile",
    organization_details: "Setup Organization Details",
    platform_configuration: "Configure Platform Settings",
    stripe_connect: "Connect Stripe Account"
  }.freeze

  STEP_DESCRIPTIONS = {
    profile: "Add your name and profile picture",
    organization_details: "Set up your organization's basic information",
    platform_configuration: "Configure essential platform settings",
    stripe_connect: "Connect your Stripe account to accept payments"
  }.freeze

  # Check if onboarding is complete
  def complete?
    profile_completed? &&
      organization_details_completed? &&
      platform_configured? &&
      stripe_connect_completed?
  end

  # Calculate completion percentage
  def progress_percentage
    total_steps = 4
    completed_steps = [
      profile_completed,
      organization_details_completed,
      platform_configured,
      stripe_connect_completed
    ].count(true)

    (completed_steps.to_f / total_steps * 100).round
  end

  # Get current step name
  def current_step_name
    STEPS[current_step]
  end

  # Get step name by index
  def step_name(step_index)
    STEPS[step_index]
  end

  # Check if a specific step is completed
  def step_completed?(step_name)
    case step_name.to_sym
    when :profile
      profile_completed?
    when :organization_details
      organization_details_completed?
    when :platform_configuration
      platform_configured?
    when :stripe_connect
      stripe_connect_completed?
    else
      false
    end
  end

  # Mark a specific step as complete
  def complete_step!(step_name)
    case step_name.to_sym
    when :profile
      update!(profile_completed: true)
    when :organization_details
      update!(organization_details_completed: true)
    when :platform_configuration
      update!(platform_configured: true)
    when :stripe_connect
      update!(stripe_connect_completed: true)
    end

    # Check if all steps are complete
    if complete?
      update!(completed_at: Time.current)
    end
  end

  # Advance to next step
  def advance_step!
    return if current_step >= 3 # Max step is 3 (0-indexed)
    update!(current_step: current_step + 1)
  end

  # Go to specific step
  def go_to_step!(step_index)
    return unless step_index.between?(0, 3)
    update!(current_step: step_index)
  end

  # Get all steps with their completion status
  def steps_with_status
    STEPS.map do |index, step_name|
      {
        index: index,
        name: step_name,
        display_name: STEP_NAMES[step_name],
        description: STEP_DESCRIPTIONS[step_name],
        completed: step_completed?(step_name),
        current: current_step == index
      }
    end
  end
end
