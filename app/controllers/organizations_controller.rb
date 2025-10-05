# frozen_string_literal: true

# OrganizationsController
# Manages organization CRUD operations and organization switching
class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :show, :edit, :update ]
  before_action :require_admin_access, only: [ :edit, :update ]

  # GET /organizations
  # List all organizations the current user belongs to
  def index
    @organizations = current_user.organizations.order(created_at: :desc)
  end

  # GET /organizations/new
  # Form to create a new organization
  def new
    @organization = Organization.new
  end

  # POST /organizations
  # Create a new organization
  def create
    @organization = Organization.new(organization_params)
    @organization.owner = current_user

    if @organization.save
      # Create owner membership
      @organization.organization_memberships.create!(user: current_user, role: :admin)

      # Switch to the new organization
      switch_organization(@organization.id)

      redirect_to @organization, notice: "Organization created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /organizations/:id
  # Show organization details
  def show
    # Only members can view
    unless current_user.organizations.include?(@organization)
      redirect_to organizations_path, alert: "You don't have access to this organization."
    end
  end

  # GET /organizations/:id/edit
  # Organization settings page with tabs for general, billing, and Stripe Connect
  def edit
    # Tabs: general, billing, stripe_connect
  end

  # PATCH /organizations/:id
  # Update organization settings
  def update
    if @organization.update(organization_params)
      redirect_to @organization, notice: "Organization settings updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # POST /organizations/:id/switch
  # Switch the current organization context
  def switch
    organization = current_user.organizations.find_by(id: params[:id])

    if organization && switch_organization(organization.id)
      redirect_back fallback_location: root_path, notice: "Switched to #{organization.name}"
    else
      redirect_back fallback_location: root_path, alert: "Unable to switch organizations."
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :slug)
  end

  # Ensure only organization admins can access settings
  def require_admin_access
    membership = current_user.organization_memberships.find_by(organization: @organization)
    unless membership&.admin?
      redirect_to @organization, alert: "You don't have permission to manage this organization's settings."
    end
  end
end
