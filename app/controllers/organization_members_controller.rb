class OrganizationMembersController < ApplicationController
  layout "dashboard"
  before_action :set_organization
  before_action :require_organization_admin, only: [ :update, :destroy ]
  before_action :set_membership, only: [ :update, :destroy ]

  def index
    @memberships = @organization.organization_memberships
                                .includes(:user)
                                .order(created_at: :asc)
  end

  def update
    # Prevent owner from changing their own role
    if @membership.user_id == @organization.owner_id
      redirect_to organization_members_path(@organization), alert: "Cannot change the owner's role."
      return
    end

    # Validate and set role explicitly
    new_role = validated_role(params[:organization_membership][:role])
    @membership.role = new_role

    if @membership.save
      redirect_to organization_members_path(@organization), notice: "Member role updated successfully."
    else
      redirect_to organization_members_path(@organization), alert: "Failed to update member role."
    end
  end

  def destroy
    # Prevent owner from being removed
    if @membership.user_id == @organization.owner_id
      redirect_to organization_members_path(@organization), alert: "Cannot remove the organization owner."
      return
    end

    # Prevent user from removing themselves
    if @membership.user_id == current_user.id
      redirect_to organization_members_path(@organization), alert: "Cannot remove yourself. Transfer ownership first if you want to leave."
      return
    end

    @membership.destroy
    redirect_to organization_members_path(@organization), notice: "Member removed successfully."
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:organization_id])
  end

  def set_membership
    @membership = @organization.organization_memberships.find(params[:id])
  end

  # Validate and return a safe role value
  def validated_role(role_param)
    allowed_roles = OrganizationMembership.roles.keys
    if role_param.present? && allowed_roles.include?(role_param)
      role_param
    else
      @membership.role # Keep existing role if invalid value provided
    end
  end
end
