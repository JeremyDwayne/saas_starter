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
