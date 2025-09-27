module Madmin
  class ApplicationController < Madmin::BaseController
    include Authentication
    include Authorization

    # Include helpers for shared partials
    helper IconHelper

    before_action :authenticate_admin_user

    private

    def authenticate_admin_user
      redirect_to "/", alert: "You must be an administrator to access the admin dashboard." unless authenticated? && Current.user&.admin?
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to "/signin"
    end
  end
end
