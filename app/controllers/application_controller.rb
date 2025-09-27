class ApplicationController < ActionController::Base
  set_referral_cookie
  include Authentication

  # Debug method to check referral cookie setting (development only)
  after_action :log_referral_cookie, if: -> { Rails.env.development? && params[:ref].present? }
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  helper_method :current_user

  def current_user
    Current.user
  end

  private

  def log_referral_cookie
    Rails.logger.info "Referral param received: #{params[:ref]}"
    Rails.logger.info "Referral cookie set: #{cookies[:refer_code]}"
  end
end
