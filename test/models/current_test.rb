require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @admin = users(:admin)
    @organization = organizations(:one)
    @membership = OrganizationMembership.create!(user: @user, organization: @organization, role: :member)
  end

  teardown do
    Current.reset
  end

  test "impersonating? returns false when not impersonating" do
    session = Session.create!(user: @user, ip_address: "127.0.0.1")
    Current.session = session

    assert_not Current.impersonating?
  end

  test "impersonating? returns true when impersonating user" do
    session = Session.create!(
      user: @user,
      impersonator_id: @admin.id,
      ip_address: "127.0.0.1"
    )
    Current.session = session

    assert Current.impersonating?
    assert_equal @admin, Current.impersonator
  end

  test "impersonating? returns true when impersonating role" do
    session = Session.create!(
      user: @admin,
      impersonated_role: "owner",
      ip_address: "127.0.0.1"
    )
    Current.session = session

    assert Current.impersonating?
    assert_equal "owner", Current.impersonated_role
  end

  test "role returns impersonated_role when impersonating" do
    session = Session.create!(
      user: @admin,
      impersonated_role: "owner",
      ip_address: "127.0.0.1"
    )
    Current.session = session
    Current.organization = @organization
    Current.membership = @membership

    assert_equal :owner, Current.role
  end

  test "owner? returns true when impersonating owner role" do
    session = Session.create!(
      user: @admin,
      impersonated_role: "owner",
      ip_address: "127.0.0.1"
    )
    Current.session = session

    assert Current.owner?
  end

  test "admin? returns true when impersonating admin role" do
    session = Session.create!(
      user: @admin,
      impersonated_role: "admin",
      ip_address: "127.0.0.1"
    )
    Current.session = session

    assert Current.admin?
  end

  test "admin? returns true when impersonating owner role" do
    session = Session.create!(
      user: @admin,
      impersonated_role: "owner",
      ip_address: "127.0.0.1"
    )
    Current.session = session

    assert Current.admin?
  end

  test "member? returns true when impersonating any role" do
    session = Session.create!(
      user: @admin,
      impersonated_role: "member",
      ip_address: "127.0.0.1"
    )
    Current.session = session

    assert Current.member?
  end
end
