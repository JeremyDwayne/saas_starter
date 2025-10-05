class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to signin_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user, source: :password_login # TODO: change here

      # Check for invitation token and accept if present
      if session[:invitation_token].present?
        invitation = OrganizationInvitation.find_by(token: session[:invitation_token])

        if invitation && invitation.pending? && !invitation.expired? && invitation.email == user.email_address
          membership = invitation.accept!(user)

          if membership
            session.delete(:invitation_token)
            session[:current_organization_id] = invitation.organization_id
            redirect_to organization_path(invitation.organization), notice: "You've successfully joined #{invitation.organization.name}!"
            return
          end
        else
          session.delete(:invitation_token)
        end
      end

      # Check if user needs to create their first organization
      if user.organizations.none?
        flash[:notice] = "Welcome back! Let's create your first organization to get started."
        redirect_to new_organization_path
      else
        redirect_to after_authentication_url
      end
    else
      redirect_to signin_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to signin_path, status: :see_other
  end
end
