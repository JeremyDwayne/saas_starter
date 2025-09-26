class SettingsController < ApplicationController
  layout "dashboard"
  before_action :set_user

  def show
    # Show the settings page
  end

  def update_profile
    if @user.update(profile_params)
      redirect_to settings_path, notice: "Profile updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    @user.validation_context = :password_change

    if @user.update(password_params)
      redirect_to settings_path, notice: "Password updated successfully."
    else
      render :show, status: :unprocessable_entity
    end
  end


  def destroy_account
    if params[:confirmation] == "DELETE"
      # Cancel subscription if active
      Current.user.subscription&.cancel_now!

      # Delete all user data
      Current.user.sessions.destroy_all
      Current.user.destroy

      redirect_to root_path, notice: "Your account has been deleted successfully."
    else
      redirect_to settings_path, alert: "Account deletion confirmation failed."
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def profile_params
    params.require(:user).permit(:name, :email_address, :avatar_url)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
