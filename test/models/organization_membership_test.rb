require "test_helper"

class OrganizationMembershipTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @organization = Organization.create!(name: "Test Org", owner: @user)
  end

  test "valid membership" do
    membership = OrganizationMembership.new(user: @user, organization: @organization)
    assert membership.valid?
  end

  test "requires user" do
    membership = OrganizationMembership.new(organization: @organization)
    assert_not membership.valid?
  end

  test "requires organization" do
    membership = OrganizationMembership.new(user: @user)
    assert_not membership.valid?
  end

  test "belongs to user" do
    membership = OrganizationMembership.create!(user: @user, organization: @organization)
    assert_equal @user, membership.user
  end

  test "belongs to organization" do
    membership = OrganizationMembership.create!(user: @user, organization: @organization)
    assert_equal @organization, membership.organization
  end

  test "defaults to member role" do
    membership = OrganizationMembership.create!(user: @user, organization: @organization)
    assert membership.member?
    assert_not membership.admin?
    assert_equal "member", membership.role
  end

  test "can be assigned admin role" do
    membership = OrganizationMembership.create!(user: @user, organization: @organization, role: :admin)
    assert membership.admin?
    assert_not membership.member?
    assert_equal "admin", membership.role
  end

  test "role can be changed" do
    membership = OrganizationMembership.create!(user: @user, organization: @organization)
    assert membership.member?

    membership.update!(role: :admin)
    assert membership.admin?
  end

  test "validates uniqueness of user scoped to organization" do
    OrganizationMembership.create!(user: @user, organization: @organization)

    duplicate = OrganizationMembership.new(user: @user, organization: @organization)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "allows same user in different organizations" do
    org1 = @organization
    org2 = Organization.create!(name: "Another Org", owner: @user)

    membership1 = OrganizationMembership.create!(user: @user, organization: org1)
    membership2 = OrganizationMembership.create!(user: @user, organization: org2)

    assert membership1.valid?
    assert membership2.valid?
  end

  test "allows different users in same organization" do
    user2 = User.create!(
      email_address: "test2@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    membership1 = OrganizationMembership.create!(user: @user, organization: @organization)
    membership2 = OrganizationMembership.create!(user: user2, organization: @organization)

    assert membership1.valid?
    assert membership2.valid?
  end
end
