# frozen_string_literal: true

# OrganizationContext concern
# Sets the current organization context from the session for multi-tenancy
module OrganizationContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_organization
  end

  private

  # Set the current organization from session
  # Falls back to user's first organization if not set
  def set_current_organization
    return unless Current.user

    organization_id = session[:current_organization_id]

    # Find organization and verify user has access
    if organization_id.present?
      organization = current_user.organizations.find_by(id: organization_id)
    end

    # Fallback to first organization if session org not found or not accessible
    organization ||= current_user.organizations.first

    # Set context
    if organization
      Current.organization = organization
      Current.membership = current_user.organization_memberships.find_by(organization: organization)

      # Update session if we fell back to a different org
      session[:current_organization_id] = organization.id
    else
      # User has no organizations - they need to create one
      Current.organization = nil
      Current.membership = nil
      session[:current_organization_id] = nil
    end
  end

  # Switch to a different organization
  # @param organization_id [String] The ID of the organization to switch to
  # @return [Boolean] True if switch was successful
  def switch_organization(organization_id)
    organization = current_user.organizations.find_by(id: organization_id)

    if organization
      session[:current_organization_id] = organization.id
      Current.organization = organization
      Current.membership = current_user.organization_memberships.find_by(organization: organization)
      true
    else
      false
    end
  end

  # Require that an organization context is set
  # Redirects to organization selection if not set
  def require_organization_context
    return if Current.organization.present?

    redirect_to new_organization_path, alert: "Please create or select an organization to continue."
  end
end
