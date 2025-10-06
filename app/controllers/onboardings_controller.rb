# OnboardingsController
# Manages the onboarding flow for new organizations after subscription
class OnboardingsController < ApplicationController
  layout "dashboard"
  before_action :require_organization_context
  before_action :set_onboarding
  before_action :check_onboarding_exists, only: [ :show, :update, :skip_step ]

  # GET /onboardings/:id
  # Show current onboarding step
  def show
    # Redirect to dashboard if onboarding is complete
    if @onboarding.complete?
      redirect_to dashboard_path, notice: "Onboarding already completed!"
      return
    end

    # Set instance variables for the current step
    @current_step_index = @onboarding.current_step
    @current_step_name = @onboarding.current_step_name
    @steps = @onboarding.steps_with_status

    # Load data needed for specific steps
    case @current_step_name
    when :profile
      @user = Current.user
    when :organization_details
      @organization = Current.organization
    when :platform_configuration
      # Add any platform configuration data here
    when :stripe_connect
      @fee_percentage = Current.organization.platform_fee_percentage
      @stripe_connected = Current.organization.merchant_onboarding_complete?
    end
  end

  # PATCH /onboardings/:id
  # Update current step and advance to next
  def update
    step_name = params[:step_name]&.to_sym

    case step_name
    when :profile
      if update_profile
        @onboarding.complete_step!(:profile)
        advance_or_complete
      else
        render_step_error(:profile)
      end
    when :organization_details
      if update_organization_details
        @onboarding.complete_step!(:organization_details)
        advance_or_complete
      else
        render_step_error(:organization_details)
      end
    when :platform_configuration
      # Platform configuration can be skipped or completed
      @onboarding.complete_step!(:platform_configuration)
      advance_or_complete
    when :stripe_connect
      # Stripe Connect is handled by ConnectedAccountsController
      # This just marks it complete if merchant onboarding is done
      if Current.organization.merchant_onboarding_complete?
        @onboarding.complete_step!(:stripe_connect)
        advance_or_complete
      else
        redirect_to new_connected_account_path, notice: "Please complete Stripe Connect setup."
      end
    else
      redirect_to onboarding_path(@onboarding), alert: "Invalid step."
    end
  end

  # PATCH /onboardings/:id/skip_step
  # Skip current step (for optional steps only)
  def skip_step
    step_name = params[:step_name]&.to_sym

    # Only allow skipping optional steps
    skippable_steps = [ :platform_configuration ]

    if skippable_steps.include?(step_name)
      @onboarding.complete_step!(step_name)
      @onboarding.advance_step!

      redirect_to onboarding_path(@onboarding), notice: "Step skipped. You can complete it later from settings."
    else
      redirect_to onboarding_path(@onboarding), alert: "This step cannot be skipped."
    end
  end

  # PATCH /onboardings/:id/complete
  # Mark entire onboarding as complete (if all steps done)
  def complete
    if @onboarding.complete?
      @onboarding.update!(completed_at: Time.current)
      redirect_to dashboard_path, notice: "Congratulations! Your organization is all set up!"
    else
      redirect_to onboarding_path(@onboarding), alert: "Please complete all required steps first."
    end
  end

  private

  def set_onboarding
    @onboarding = Current.organization.onboarding
  end

  def check_onboarding_exists
    unless @onboarding
      redirect_to dashboard_path, alert: "No onboarding found for this organization."
    end
  end

  def update_profile
    user = Current.user
    user_params = params.require(:user).permit(:name, :avatar_url)

    user.update(user_params)
  end

  def update_organization_details
    organization = Current.organization
    org_params = params.require(:organization).permit(:name, :slug)

    organization.update(org_params)
  end

  def advance_or_complete
    if @onboarding.complete?
      @onboarding.update!(completed_at: Time.current)
      redirect_to dashboard_path, notice: "🎉 Congratulations! Your organization is all set up!"
    else
      @onboarding.advance_step!
      redirect_to onboarding_path(@onboarding), notice: "Step completed! Moving to next step."
    end
  end

  def render_step_error(step_name)
    @current_step_index = @onboarding.current_step
    @current_step_name = step_name
    @steps = @onboarding.steps_with_status

    case step_name
    when :profile
      @user = Current.user
    when :organization_details
      @organization = Current.organization
    end

    flash.now[:alert] = "Please fix the errors below."
    render :show, status: :unprocessable_entity
  end
end
