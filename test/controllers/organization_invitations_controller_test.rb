require "test_helper"

class OrganizationInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = Organization.create!(owner: @user, name: "Test Organization")
    OrganizationMembership.create!(user: @user, organization: @organization, role: :admin)
    sign_in_as @user
  end

  test "should get index" do
    get organization_invitations_url(@organization)
    assert_response :success
  end

  test "should get new" do
    get new_organization_invitation_url(@organization)
    assert_response :success
  end

  test "should create invitation" do
    assert_difference("OrganizationInvitation.count", 1) do
      post organization_invitations_url(@organization), params: {
        organization_invitation: { email: "newmember@example.com", role: "member" }
      }
    end
    assert_redirected_to organization_invitations_path(@organization)
  end

  test "should revoke invitation" do
    invitation = OrganizationInvitation.create!(
      organization: @organization,
      email: "test@example.com",
      role: "member",
      invited_by: @user
    )

    delete organization_invitation_url(@organization, invitation)
    assert_redirected_to organization_invitations_path(@organization)
    assert_equal "revoked", invitation.reload.status
  end

  test "should accept invitation for signed in user" do
    # Create a second organization to invite the user to
    other_user = User.create!(email_address: "other@example.com", password: "password123")
    other_organization = Organization.create!(owner: other_user, name: "Other Organization")

    invitation = OrganizationInvitation.create!(
      organization: other_organization,
      email: @user.email_address,
      role: "member",
      invited_by: other_user
    )

    get accept_organization_invitation_url(token: invitation.token)
    assert_redirected_to organization_path(other_organization)
    assert_equal "accepted", invitation.reload.status
  end

  test "should redirect to signup for unauthenticated user" do
    sign_out
    invitation = OrganizationInvitation.create!(
      organization: @organization,
      email: "newuser@example.com",
      role: "member",
      invited_by: @user
    )

    get accept_organization_invitation_url(token: invitation.token)
    assert_redirected_to signup_path
    assert_equal invitation.token, session[:invitation_token]
  end
end
