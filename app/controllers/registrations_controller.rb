class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save(context: :registration)
      refer @user #=> Looks up cookie and attempts referral

      # Log referral creation in development
      if Rails.env.development? && (referral = Refer::Referral.find_by(referee: @user))
        Rails.logger.info "Referral created: Referrer #{referral.referrer_id}, Referee #{referral.referee_id}"
      end

      start_new_session_for(@user, source: "registration")

      # Check for invitation token and accept if present
      if session[:invitation_token].present?
        invitation = OrganizationInvitation.find_by(token: session[:invitation_token])

        if invitation && invitation.pending? && !invitation.expired? && invitation.email == @user.email_address
          membership = invitation.accept!(@user)

          if membership
            session.delete(:invitation_token)
            session[:current_organization_id] = invitation.organization_id
            flash[:notice] = "Welcome! You've successfully joined #{invitation.organization.name}."
            redirect_to organization_path(invitation.organization)
            return
          end
        else
          session.delete(:invitation_token)
        end
      end

      flash[:notice] = "Welcome! Your account has been created successfully."
      redirect_to after_authentication_url
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
