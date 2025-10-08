require "test_helper"

class ImpersonationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular_user = users(:one)
    @another_admin = users(:another_admin)
  end

  test "non-admin cannot access impersonation" do
    sign_in_as @regular_user

    post impersonate_user_path(@regular_user)
    assert_redirected_to root_path
    assert_equal "Only administrators can use impersonation.", flash[:alert]
  end

  test "admin can impersonate regular user" do
    sign_in_as @admin

    post impersonate_user_path(@regular_user)
    assert_redirected_to root_path
    assert_equal "Now impersonating #{@regular_user.email_address}", flash[:notice]

    # Verify impersonation is active
    follow_redirect!
    session = Session.find_by(user_id: @regular_user.id, impersonator_id: @admin.id)
    assert_not_nil session
  end

  test "admin cannot impersonate another admin" do
    sign_in_as @admin

    post impersonate_user_path(@another_admin)
    assert_redirected_to root_path
    assert_equal "You cannot impersonate other administrators.", flash[:alert]
  end

  test "admin can impersonate a role" do
    sign_in_as @admin

    post impersonate_role_path(role_name: "owner")
    assert_redirected_to root_path
    assert_equal "Now impersonating role: owner", flash[:notice]

    # Verify role impersonation is active via reloading session
    Current.session.reload
    assert_equal "owner", Current.session.impersonated_role
  end

  test "admin cannot impersonate invalid role" do
    sign_in_as @admin

    post impersonate_role_path(role_name: "invalid_role")
    assert_redirected_to root_path
    assert_equal "Invalid role: invalid_role", flash[:alert]
  end

  test "admin can stop impersonating user" do
    sign_in_as @admin
    original_session_id = Current.session.id

    # Start impersonation
    post impersonate_user_path(@regular_user)
    assert_redirected_to root_path

    # Verify impersonation is active
    impersonating_session = Session.find(original_session_id)
    assert_equal @regular_user.id, impersonating_session.user_id
    assert_equal @admin.id, impersonating_session.impersonator_id

    # Stop impersonation
    delete stop_impersonation_path
    assert_redirected_to root_path

    # Verify impersonation stopped
    restored_session = Session.find(original_session_id)
    assert_equal @admin.id, restored_session.user_id
    assert_nil restored_session.impersonator_id
  end

  test "admin can stop impersonating role" do
    sign_in_as @admin

    # Start role impersonation
    post impersonate_role_path(role_name: "owner")
    Current.session.reload
    assert_equal "owner", Current.session.impersonated_role

    # Stop impersonation
    delete stop_impersonation_path
    assert_redirected_to root_path
    assert_equal "Stopped impersonating role", flash[:notice]

    # Verify role impersonation stopped
    Current.session.reload
    assert_nil Current.session.impersonated_role
  end

  test "cannot stop impersonation when not impersonating" do
    sign_in_as @admin

    delete stop_impersonation_path
    assert_redirected_to root_path
    assert_equal "Not currently impersonating", flash[:alert]
  end
end
