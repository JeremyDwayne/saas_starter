class OrganizationInvitationMailer < ApplicationMailer
  def invitation_email(invitation)
    @invitation = invitation
    @organization = invitation.organization
    @invited_by = invitation.invited_by
    @accept_url = accept_organization_invitation_url(token: invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@organization.name}"
    )
  end
end
