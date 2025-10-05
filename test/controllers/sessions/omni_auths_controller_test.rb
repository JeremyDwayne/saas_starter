require "test_helper"

class Sessions::OmniAuthsControllerTest < ActionDispatch::IntegrationTest
  test "handle OAuth failure" do
    get "/auth/failure"

    assert_redirected_to signin_path
    follow_redirect!
    assert_alert "Authentication failed, please try again."
  end

  test "User.create_from_oauth creates user with password" do
    auth_hash = OmniAuth::AuthHash.new({
      "uid" => "12345",
      "provider" => "google_oauth2",
      "info" => {
        "email" => "oauth_test@example.com",
        "name" => "OAuth Test User"
      }
    })

    assert_difference "User.count" do
      user = User.create_from_oauth(auth_hash)
      assert user.persisted?
      assert user.password_digest.present?
      assert_equal "oauth_test@example.com", user.email_address
    end
  end

  test "OmniAuthIdentity can be created with user" do
    user = User.create!(email_address: "identity_test@example.com", password: "password123")

    assert_difference "OmniAuthIdentity.count" do
      identity = OmniAuthIdentity.create!(
        uid: "test_uid_123",
        provider: "google_oauth2",
        user: user
      )

      assert identity.persisted?
      assert_equal user, identity.user
      assert_equal "test_uid_123", identity.uid
      assert_equal "google_oauth2", identity.provider
    end
  end

  test "OmniAuthIdentity requires user_id" do
    # This should fail because user_id is required
    assert_raises ActiveRecord::RecordInvalid do
      OmniAuthIdentity.create!(
        uid: "test_uid_456",
        provider: "github"
        # Missing user - should cause validation error
      )
    end
  end

  test "OAuth referral tracking for new users" do
    referrer = users(:one)
    referral_code = referrer.referral_codes.create

    # Test that referral tracking works in the model layer
    new_user = User.create!(
      email_address: "referral_test@example.com",
      name: "Referral Test User",
      password: "password123"
    )

    # Simulate what the refer method does
    result = Refer.refer(code: referral_code.code, referee: new_user)

    # Check that referral was created
    referral = referrer.referrals.find_by(referee: new_user)
    assert referral.present?, "Referral should be created"
    assert_equal referrer, referral.referrer
    assert_equal new_user, referral.referee
  end

  test "OAuth sign-in accepts pending invitation for existing user" do
    # Setup: Create organization and invitation
    organization = organizations(:one)
    invited_email = "existing_oauth@example.com"

    # Create existing user with this email
    existing_user = User.create!(
      email_address: invited_email,
      password: "password123"
    )

    invitation = organization.organization_invitations.create!(
      email: invited_email,
      role: "member",
      invited_by: users(:one)
    )

    assert invitation.pending?
    assert_not organization.users.include?(existing_user)

    # Simulate clicking invitation link (stores token in session)
    get accept_organization_invitation_path(token: invitation.token)
    assert_redirected_to signup_path
    assert_equal invitation.token, session[:invitation_token]

    # Setup OAuth test mode
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      "uid" => "google_12345",
      "provider" => "google_oauth2",
      "info" => {
        "email" => invited_email,
        "name" => "OAuth Test User"
      }
    })

    # Simulate OAuth callback
    assert_difference "OrganizationMembership.count" do
      get "/auth/google_oauth2/callback"
    end

    # Verify invitation was accepted
    assert_redirected_to organization_path(organization)
    follow_redirect!
    assert_notice "You've successfully joined #{organization.name}!"

    # Verify membership was created
    membership = organization.organization_memberships.find_by(user: existing_user)
    assert membership.present?
    assert_equal "member", membership.role

    # Verify invitation is no longer pending
    assert_not invitation.reload.pending?

    # Verify session token was cleared
    assert_nil session[:invitation_token]

    # Verify organization context was set
    assert_equal organization.id, session[:current_organization_id]

    # Cleanup
    OmniAuth.config.test_mode = false
  end

  test "OAuth sign-in accepts pending invitation for new user" do
    # Setup: Create organization and invitation
    organization = organizations(:one)
    invited_email = "new_oauth@example.com"

    invitation = organization.organization_invitations.create!(
      email: invited_email,
      role: "admin",
      invited_by: users(:one)
    )

    assert invitation.pending?

    # Simulate clicking invitation link (stores token in session)
    get accept_organization_invitation_path(token: invitation.token)
    assert_redirected_to signup_path
    assert_equal invitation.token, session[:invitation_token]

    # Setup OAuth test mode
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      "uid" => "google_67890",
      "provider" => "google_oauth2",
      "info" => {
        "email" => invited_email,
        "name" => "New OAuth User"
      }
    })

    # Simulate OAuth callback - should create user AND accept invitation
    assert_difference [ "User.count", "OrganizationMembership.count" ] do
      get "/auth/google_oauth2/callback"
    end

    # Verify invitation was accepted
    assert_redirected_to organization_path(organization)
    follow_redirect!
    assert_notice "You've successfully joined #{organization.name}!"

    # Verify user was created
    new_user = User.find_by(email_address: invited_email)
    assert new_user.present?

    # Verify membership was created with correct role
    membership = organization.organization_memberships.find_by(user: new_user)
    assert membership.present?
    assert_equal "admin", membership.role

    # Verify invitation is no longer pending
    assert_not invitation.reload.pending?

    # Verify session token was cleared
    assert_nil session[:invitation_token]

    # Cleanup
    OmniAuth.config.test_mode = false
  end
end
