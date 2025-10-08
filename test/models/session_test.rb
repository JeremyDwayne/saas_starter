require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @admin = users(:admin)
  end

  test "session without impersonation is not impersonating" do
    session = Session.create!(user: @user, ip_address: "127.0.0.1")
    assert_not session.impersonating?
    assert_not session.impersonating_user?
    assert_not session.impersonating_role?
  end

  test "session with impersonator_id is impersonating user" do
    session = Session.create!(
      user: @user,
      impersonator_id: @admin.id,
      ip_address: "127.0.0.1"
    )

    assert session.impersonating?
    assert session.impersonating_user?
    assert_not session.impersonating_role?
    assert_equal @admin, session.impersonator
  end

  test "session with impersonated_role is impersonating role" do
    session = Session.create!(
      user: @admin,
      impersonated_role: "owner",
      ip_address: "127.0.0.1"
    )

    assert session.impersonating?
    assert_not session.impersonating_user?
    assert session.impersonating_role?
    assert_equal "owner", session.impersonated_role
  end

  test "session can impersonate both user and role simultaneously" do
    session = Session.create!(
      user: @user,
      impersonator_id: @admin.id,
      impersonated_role: "owner",
      ip_address: "127.0.0.1"
    )

    assert session.impersonating?
    assert session.impersonating_user?
    assert session.impersonating_role?
  end
end
