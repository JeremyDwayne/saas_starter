class PagesController < ApplicationController
  allow_unauthenticated_access except: [ :dashboard ]
  layout "dashboard", only: [ :dashboard ]
  before_action :ensure_organization_context, only: [ :home, :pricing ], if: -> { authenticated? }

  def home
    # Demo flash messages for testing toasts
    if params[:demo_flash]
      case params[:demo_flash]
      when "success"
        flash[:notice] = "Your account has been created successfully!"
      when "error"
        flash[:alert] = "There was an error processing your request."
      when "warning"
        flash[:warning] = "Your session will expire in 5 minutes."
      when "info"
        flash[:info] = "New features have been added to your dashboard."
      end
      redirect_to root_path
    end
  end

  def pricing
    # Get current subscription info if user has an organization
    @current_plan = nil
    if Current.organization&.subscribed?
      subscription = Current.organization.subscription
      # Extract plan name from subscription (e.g., "professional", "personal", "enterprise")
      @current_plan = subscription.name&.downcase
    end
  end

  def dashboard
    """Dashboard page for authenticated users"""
    # Authentication is handled by ApplicationController automatically

    # Load onboarding if it exists and is incomplete
    @onboarding = Current.organization&.onboarding
  end

  private

  def ensure_organization_context
    # Force set organization context if not already set
    if current_user.present? && current_organization.nil? && current_user.organizations.any?
      first_org = current_user.organizations.first
      session[:current_organization_id] = first_org.id
      Current.organization = first_org
      Current.membership = current_user.organization_memberships.find_by(organization: first_org)
    end
  end
end
