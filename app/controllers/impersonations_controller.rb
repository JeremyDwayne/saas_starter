# frozen_string_literal: true

# ImpersonationsController
# Allows admin users to impersonate other users or roles for troubleshooting
class ImpersonationsController < ApplicationController
  before_action :require_admin_user
  before_action :set_target_user, only: :create_user
  before_action :validate_role, only: :create_role

  # POST /impersonate/user/:id
  # Start impersonating a specific user
  def create_user
    # Prevent impersonating other admins for security
    if @target_user.admin?
      redirect_back fallback_location: root_path, alert: "You cannot impersonate other administrators."
      return
    end

    # Update current session with impersonation info
    Current.session.update!(
      impersonator_id: Current.user.id,
      impersonated_role: nil
    )

    # Switch the session user to the target user
    Current.session.update!(user_id: @target_user.id)

    # Reset organization context to target user's first organization
    session[:current_organization_id] = @target_user.organizations.first&.id

    redirect_to root_path, notice: "Now impersonating #{@target_user.email_address}"
  end

  # POST /impersonate/role/:role_name
  # Start impersonating a role without a specific user
  def create_role
    # Update current session with role impersonation
    Current.session.update!(
      impersonator_id: nil,
      impersonated_role: params[:role_name]
    )

    redirect_back fallback_location: root_path, notice: "Now impersonating role: #{params[:role_name]}"
  end

  # DELETE /impersonate
  # Stop impersonating and return to original user
  def destroy
    # Get the original admin user before clearing impersonation
    impersonator = Current.session.impersonator
    was_impersonating_role = Current.session.impersonating_role?

    if Current.session.impersonating_user?
      # Switch back to the impersonator
      Current.session.update!(
        user_id: impersonator.id,
        impersonator_id: nil,
        impersonated_role: nil
      )

      # Reset organization context to impersonator's first organization
      session[:current_organization_id] = impersonator.organizations.first&.id

      redirect_to root_path, notice: "Stopped impersonating user"
    elsif was_impersonating_role
      # Just clear the role impersonation
      Current.session.update!(
        impersonator_id: nil,
        impersonated_role: nil
      )

      redirect_back fallback_location: root_path, notice: "Stopped impersonating role"
    else
      redirect_back fallback_location: root_path, alert: "Not currently impersonating"
    end
  end

  private

  # Ensure only admin users can impersonate
  # When already impersonating, check the real user (impersonator), not the impersonated user
  def require_admin_user
    real_admin = Current.impersonator || Current.user

    unless real_admin&.admin?
      redirect_to root_path, alert: "Only administrators can use impersonation."
    end
  end

  # Find the target user to impersonate
  def set_target_user
    @target_user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "User not found."
  end

  # Validate the role name is valid
  def validate_role
    valid_roles = %w[owner admin member]

    unless valid_roles.include?(params[:role_name])
      redirect_back fallback_location: root_path, alert: "Invalid role: #{params[:role_name]}"
    end
  end
end
