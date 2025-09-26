class PagesController < ApplicationController
  allow_unauthenticated_access except: [ :dashboard ]

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
  end

  def dashboard
    """Dashboard page for authenticated users"""
    # Authentication is handled by ApplicationController automatically
  end
end
