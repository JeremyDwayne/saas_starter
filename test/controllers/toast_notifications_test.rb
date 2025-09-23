require "test_helper"

class ToastNotificationsTest < ActionDispatch::IntegrationTest
  test "successful signup shows toast notification" do
    post signup_path, params: {
      user: {
        email_address: "toast@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to root_path
    follow_redirect!

    # The flash message should be available for the toast system
    assert_notice "Welcome! Your account has been created successfully."
  end

  test "failed signin shows alert toast" do
    post signin_path, params: {
      email_address: "nonexistent@example.com",
      password: "wrongpassword"
    }

    assert_redirected_to signin_path
    follow_redirect!
    assert_alert "Try another email address or password."
  end

  test "password reset request shows notice toast" do
    user = User.take
    post passwords_path, params: { email_address: user.email_address }

    assert_redirected_to signin_path
    follow_redirect!
    assert_notice "Password reset instructions sent"
  end


  test "demo flash messages work for testing toasts" do
    get root_path(demo_flash: "success")
    assert_redirected_to root_path

    follow_redirect!
    assert_notice "Your account has been created successfully!"
  end
end
