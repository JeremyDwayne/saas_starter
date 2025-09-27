module Authorization
  extend ActiveSupport::Concern

  class AuthorizationError < StandardError; end

  included do
    rescue_from Authorization::AuthorizationError, with: :handle_authorization_error
  end

  class_methods do
    def require_role(role_name, **options)
      before_action -> { authorize_role!(role_name) }, **options
    end

    def require_permission(permission_name, **options)
      before_action -> { authorize_permission!(permission_name) }, **options
    end

    def require_permission_for(resource, action, **options)
      before_action -> { authorize_permission_for!(resource, action) }, **options
    end

    def require_admin(**options)
      require_role(:admin, **options)
    end
  end

  private

  def current_user
    Current.user
  end

  def authorize_role!(role_name)
    raise AuthorizationError, "Access denied" unless current_user&.has_role?(role_name)
  end

  def authorize_permission!(permission_name)
    raise AuthorizationError, "Access denied" unless current_user&.has_permission?(permission_name)
  end

  def authorize_permission_for!(resource, action)
    raise AuthorizationError, "Access denied" unless current_user&.has_permission_for?(resource, action)
  end

  def authorize_admin!
    authorize_role!(:admin)
  end

  def handle_authorization_error(exception)
    if request.format.html?
      flash[:alert] = "You are not authorized to access this page."
      redirect_to "/"
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
