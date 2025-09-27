require "test_helper"

class OAuthReferralFlowTest < ActionDispatch::IntegrationTest
  def setup
    @referrer = users(:one)
    @referral_code = @referrer.referral_codes.create

    # Mock OAuth data
    @oauth_data = {
      "provider" => "google_oauth2",
      "uid" => "12345",
      "info" => {
        "email" => "newuser@example.com",
        "name" => "New User",
        "image" => "https://example.com/avatar.jpg"
      }
    }
  end

  test "OAuth registration with referral code creates referral" do
    # Visit page with referral code first to set cookie
    get "/?ref=#{@referral_code.code}"
    assert_response :success
    assert_equal @referral_code.code, cookies[:refer_code]

    # Mock the OAuth callback
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(@oauth_data)

    # Make sure user doesn't exist yet
    assert_nil User.find_by(email_address: @oauth_data["info"]["email"])

    # Trigger OAuth callback
    assert_difference "User.count", 1 do
      assert_difference "@referrer.referrals.count", 1 do
        get "/auth/google_oauth2/callback"
      end
    end

    # Check that the referral was created
    new_user = User.find_by(email_address: @oauth_data["info"]["email"])
    assert new_user.present?

    referral = @referrer.referrals.find_by(referee: new_user)
    assert referral.present?, "Referral should have been created for OAuth user"
    assert_equal @referrer, referral.referrer
    assert_equal new_user, referral.referee
  end

  test "OAuth login for existing user does not create referral" do
    # Use unique email for this test
    existing_email = "existing_user@example.com"
    oauth_data_existing = Marshal.load(Marshal.dump(@oauth_data)) # Deep clone
    oauth_data_existing["info"]["email"] = existing_email

    # Create existing user first
    existing_user = User.create!(
      email_address: existing_email,
      name: "Existing User",
      password: "password123"
    )

    # Visit page with referral code
    get "/?ref=#{@referral_code.code}"
    assert_equal @referral_code.code, cookies[:refer_code]

    # Mock OAuth for existing user
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(oauth_data_existing)

    # OAuth login should not create new user or referral
    assert_no_difference "User.count" do
      assert_no_difference "@referrer.referrals.count" do
        get "/auth/google_oauth2/callback"
      end
    end

    # No referral should be created for existing user
    referral = @referrer.referrals.find_by(referee: existing_user)
    assert_nil referral, "No referral should be created for existing user OAuth login"
  end


  def teardown
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end
