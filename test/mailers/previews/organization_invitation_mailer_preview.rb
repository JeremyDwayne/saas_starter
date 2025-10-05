# Preview all emails at http://localhost:3000/rails/mailers/organization_invitation_mailer
class OrganizationInvitationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/organization_invitation_mailer/invitation_email
  def invitation_email
    OrganizationInvitationMailer.invitation_email
  end
end
