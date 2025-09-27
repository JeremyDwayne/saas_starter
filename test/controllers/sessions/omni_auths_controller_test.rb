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
end
