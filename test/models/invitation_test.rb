require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @organization = Organization.create!(name: "Test Org", owner: @user)
  end

  test "valid invitation" do
    invitation = Invitation.new(
      email: "newuser@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert invitation.valid?
  end

  test "automatically generates token on create" do
    invitation = Invitation.create!(
      email: "newuser@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert_not_nil invitation.token
    assert invitation.token.length > 20
  end

  test "requires email" do
    invitation = Invitation.new(
      organization: @organization,
      invited_by: @user
    )
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "can't be blank"
  end

  test "requires organization" do
    invitation = Invitation.new(
      email: "test@example.com",
      invited_by: @user
    )
    assert_not invitation.valid?
  end

  test "requires invited_by" do
    invitation = Invitation.new(
      email: "test@example.com",
      organization: @organization
    )
    assert_not invitation.valid?
  end

  test "validates email uniqueness" do
    Invitation.create!(
      email: "duplicate@example.com",
      organization: @organization,
      invited_by: @user
    )

    duplicate = Invitation.new(
      email: "duplicate@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "validates token uniqueness" do
    invitation1 = Invitation.create!(
      email: "user1@example.com",
      organization: @organization,
      invited_by: @user
    )

    # Try to create another with the same token (manually set)
    invitation2 = Invitation.new(
      email: "user2@example.com",
      organization: @organization,
      invited_by: @user,
      token: invitation1.token
    )
    assert_not invitation2.valid?
    assert_includes invitation2.errors[:token], "has already been taken"
  end

  test "belongs to organization" do
    invitation = Invitation.create!(
      email: "newuser@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert_equal @organization, invitation.organization
  end

  test "belongs to invited_by user" do
    invitation = Invitation.create!(
      email: "newuser@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert_equal @user, invitation.invited_by
  end

  test "defaults to member role" do
    invitation = Invitation.create!(
      email: "newuser@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert invitation.member?
    assert_not invitation.admin?
    assert_equal "member", invitation.role
  end

  test "can be assigned admin role" do
    invitation = Invitation.create!(
      email: "admin@example.com",
      organization: @organization,
      invited_by: @user,
      role: :admin
    )
    assert invitation.admin?
    assert_not invitation.member?
    assert_equal "admin", invitation.role
  end

  test "role can be changed" do
    invitation = Invitation.create!(
      email: "user@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert invitation.member?

    invitation.update!(role: :admin)
    assert invitation.admin?
  end

  test "accept! creates membership and destroys invitation" do
    invitation = Invitation.create!(
      email: "newmember@example.com",
      organization: @organization,
      invited_by: @user,
      role: :admin
    )

    new_user = User.create!(
      email_address: "newmember@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_difference "OrganizationMembership.count", 1 do
      assert_difference "Invitation.count", -1 do
        invitation.accept!(new_user)
      end
    end

    # Verify the membership was created with correct attributes
    membership = OrganizationMembership.find_by(user: new_user, organization: @organization)
    assert_not_nil membership
    assert_equal "admin", membership.role
    assert_equal @organization, membership.organization
    assert_equal new_user, membership.user
  end

  test "accept! rolls back on membership creation failure" do
    invitation = Invitation.create!(
      email: "rollback@example.com",
      organization: @organization,
      invited_by: @user
    )

    new_user = User.create!(
      email_address: "rollback@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Create a membership first to trigger uniqueness constraint
    OrganizationMembership.create!(
      user: new_user,
      organization: @organization
    )

    # Attempting to accept should fail and not destroy the invitation
    assert_no_difference "Invitation.count" do
      assert_raises(ActiveRecord::RecordInvalid) do
        invitation.accept!(new_user)
      end
    end

    # Invitation should still exist
    assert Invitation.exists?(invitation.id)
  end

  test "to_param returns token" do
    invitation = Invitation.create!(
      email: "param@example.com",
      organization: @organization,
      invited_by: @user
    )
    assert_equal invitation.token, invitation.to_param
  end
end
