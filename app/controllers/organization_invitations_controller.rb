class OrganizationInvitationsController < ApplicationController
  layout "dashboard"
  before_action :set_organization, except: [ :accept ]
  before_action :require_organization_admin, except: [ :accept ]
  before_action :set_invitation, only: [ :destroy ]
  allow_unauthenticated_access only: [ :accept ]

  def index
    @pending_invitations = @organization.organization_invitations
                                        .valid_invitations
                                        .includes(:invited_by)
                                        .order(created_at: :desc)
  end

  def new
    @invitation = @organization.organization_invitations.build
  end

  def create
    @invitation = @organization.organization_invitations.build(invitation_params)
    @invitation.invited_by = current_user

    # Set role with validation
    @invitation.role = validated_role(params[:organization_invitation][:role])

    # Check if user is already a member
    if @organization.users.exists?(email_address: @invitation.email)
      redirect_to organization_invitations_path(@organization), alert: "This user is already a member of the organization."
      return
    end

    # Check if there's already a pending invitation
    existing_invitation = @organization.organization_invitations
                                      .pending
                                      .find_by(email: @invitation.email)

    if existing_invitation && !existing_invitation.expired?
      redirect_to organization_invitations_path(@organization), alert: "An invitation has already been sent to this email address."
      return
    end

    if @invitation.save
      OrganizationInvitationMailer.invitation_email(@invitation).deliver_later
      redirect_to organization_invitations_path(@organization), notice: "Invitation sent successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @invitation.revoke!
    redirect_to organization_invitations_path(@organization), notice: "Invitation revoked successfully."
  end

  def accept
    @invitation = OrganizationInvitation.find_by!(token: params[:token])

    if @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
      return
    end

    unless @invitation.pending?
      redirect_to root_path, alert: "This invitation is no longer valid."
      return
    end

    # Load current user from session (needed because of allow_unauthenticated_access)
    session_record = Session.find_by(id: cookies.signed[:session_id])
    current_authenticated_user = session_record&.user

    # If user is already signed in
    if current_authenticated_user
      accept_invitation_for_user(current_authenticated_user)
    else
      # Store invitation token in session and redirect to sign up/sign in
      session[:invitation_token] = @invitation.token
      redirect_to signup_path, notice: "Please sign up or sign in to accept the invitation."
    end
  end

  private

  def set_organization
    @organization = current_user.organizations.find(params[:organization_id])
  end

  def set_invitation
    @invitation = @organization.organization_invitations.find(params[:id])
  end

  def invitation_params
    params.require(:organization_invitation).permit(:email)
  end

  # Validate and return a safe role value
  def validated_role(role_param)
    allowed_roles = OrganizationMembership.roles.keys
    if role_param.present? && allowed_roles.include?(role_param)
      role_param
    else
      "member" # Default to member if invalid or missing
    end
  end

  def accept_invitation_for_user(user)
    # Check if user email matches invitation email
    if user.email_address == @invitation.email
      membership = @invitation.accept!(user)

      if membership
        # Manually set the organization context since we're not going through normal auth flow
        session[:current_organization_id] = @invitation.organization_id
        redirect_to organization_path(@invitation.organization), notice: "You've successfully joined #{@invitation.organization.name}!"
      else
        redirect_to root_path, alert: "Failed to accept invitation."
      end
    else
      redirect_to root_path, alert: "This invitation was sent to #{@invitation.email}, but you're signed in as #{user.email_address}."
    end
  end
end
