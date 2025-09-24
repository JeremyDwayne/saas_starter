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
end
