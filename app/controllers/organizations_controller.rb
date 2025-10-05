# frozen_string_literal: true

# OrganizationsController
# Manages organization CRUD operations and organization switching
class OrganizationsController < ApplicationController
  before_action :set_organization, only: [ :show ]

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
      @organization.memberships.create!(user: current_user, role: :admin)

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
    params.require(:organization).permit(:name)
  end
end
