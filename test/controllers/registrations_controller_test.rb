require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get signup_path
    assert_response :success
    assert_select "h1", text: "Create your account"
  end

  test "create with valid user data" do
    assert_difference "User.count" do
      post signup_path, params: {
        user: {
          email_address: "test@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]

    follow_redirect!
    assert_notice "Welcome! Your account has been created successfully."
  end

  test "create with invalid email" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          email_address: "invalid-email",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "p.text-red-600", text: /is invalid/
  end

  test "create with short password" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          email_address: "test@example.com",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "p.text-red-600", text: /is too short/
  end

  test "create with mismatched passwords" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          email_address: "test@example.com",
          password: "password123",
          password_confirmation: "different123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "p.text-red-600", text: /doesn't match/
  end

  test "create with duplicate email" do
    existing_user = User.first

    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          email_address: existing_user.email_address,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "p.text-red-600", text: /has already been taken/
  end
end
