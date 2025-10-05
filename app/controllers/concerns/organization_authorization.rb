# frozen_string_literal: true

# OrganizationAuthorization concern
# Provides authorization methods based on user's role in current organization
module OrganizationAuthorization
  extend ActiveSupport::Concern

  # Require that the current user is the organization owner
  # Redirects with alert if not authorized
  def require_organization_owner
    return if Current.owner?

    redirect_back_or_to root_path, alert: "You must be the organization owner to perform this action."
  end

  # Require that the current user is an organization admin or owner
  # Redirects with alert if not authorized
  def require_organization_admin
    return if Current.admin?

    redirect_back_or_to root_path, alert: "You must be an organization admin to perform this action."
  end

  # Require that the current user is a member of the organization
  # Redirects with alert if not authorized
  def require_organization_member
    return if Current.member?

    redirect_back_or_to root_path, alert: "You must be a member of this organization to access this page."
  end

  # Check if the current user can manage a specific resource
  # @param resource [ActiveRecord::Base] The resource to check
  # @return [Boolean] True if user can manage the resource
  def can_manage?(resource)
    return false unless Current.organization

    # Resource must belong to the current organization
    return false unless resource.organization_id == Current.organization.id

    # Admin or owner can manage
    Current.admin?
  end

  # Authorize that user can manage the resource
  # Redirects if not authorized
  def authorize_resource_management!(resource)
    unless can_manage?(resource)
      redirect_back_or_to root_path, alert: "You are not authorized to manage this resource."
    end
  end

  private

  # Redirect back or to a default location
  def redirect_back_or_to(default, **options)
    redirect_to request.referer || default, **options
  end
end
