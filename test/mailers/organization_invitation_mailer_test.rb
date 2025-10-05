require "test_helper"

class OrganizationInvitationMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
    @organization = Organization.create!(owner: @user, name: "Test Organization")
    @invitation = OrganizationInvitation.create!(
      organization: @organization,
      email: "invitee@example.com",
      role: "member",
      invited_by: @user
    )
  end

  test "invitation_email" do
    mail = OrganizationInvitationMailer.invitation_email(@invitation)

    assert_equal "You've been invited to join Test Organization", mail.subject
    assert_equal [ "invitee@example.com" ], mail.to
    assert_match "Test Organization", mail.body.encoded
    assert_match @user.email_address, mail.body.encoded
  end
end
