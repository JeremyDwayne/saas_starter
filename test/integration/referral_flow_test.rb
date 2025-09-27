require "test_helper"

class ReferralFlowTest < ActionDispatch::IntegrationTest
  def setup
    @referrer = users(:one)
    @referral_code = @referrer.referral_codes.create
  end

  test "referral tracking works through registration flow" do
    # Step 1: Visit signup page with referral code
    get "/signup?ref=#{@referral_code.code}"
    assert_response :success

    # Check that the cookie was set
    assert_equal @referral_code.code, cookies[:refer_code]

    # Step 2: Register a new user
    assert_difference "User.count", 1 do
      assert_difference "@referrer.referrals.count", 1 do
        post "/signup", params: {
          user: {
            email_address: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
    end

    # Check that the referral was created
    new_user = User.find_by(email_address: "newuser@example.com")
    referral = @referrer.referrals.find_by(referee: new_user)

    assert referral.present?, "Referral should have been created"
    assert_equal @referrer, referral.referrer
    assert_equal new_user, referral.referee
    assert_equal @referral_code, referral.referral_code
  end

  test "registration without referral code works normally" do
    # Register without referral code
    assert_difference "User.count", 1 do
      post "/signup", params: {
        user: {
          email_address: "normaluser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    # No referral should be created
    new_user = User.find_by(email_address: "normaluser@example.com")
    assert_equal 0, Refer::Referral.where(referee: new_user).count
  end

  test "invalid referral code does not break registration" do
    # Visit with invalid referral code
    get "/signup?ref=invalid_code"
    assert_response :success

    # Register should still work
    assert_difference "User.count", 1 do
      post "/signup", params: {
        user: {
          email_address: "testuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    # No referral should be created
    new_user = User.find_by(email_address: "testuser@example.com")
    assert_equal 0, Refer::Referral.where(referee: new_user).count
  end
end
