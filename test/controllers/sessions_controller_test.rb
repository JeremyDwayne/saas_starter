require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get signin_path
    assert_response :success
  end

  test "create with valid credentials" do
    post signin_path, params: { email_address: @user.email_address, password: "password" }

    # Redirect depends on whether user has organizations
    if @user.organizations.any?
      assert_redirected_to root_path
    else
      assert_redirected_to new_organization_path
    end
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post signin_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to signin_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete signout_path

    assert_redirected_to signin_path
    assert_empty cookies[:session_id]
  end
end
