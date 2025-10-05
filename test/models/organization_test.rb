require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "valid organization" do
    org = Organization.new(name: "Test Organization", owner: @user)
    assert org.valid?
  end

  test "requires name" do
    org = Organization.new(owner: @user)
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "generates slug from name on create" do
    org = Organization.create!(name: "My Test Organization", owner: @user)
    assert_equal "my-test-organization", org.slug
  end

  test "generates unique slug when name conflicts" do
    Organization.create!(name: "Test Org", owner: @user, slug: "test-org")

    org2 = Organization.create!(name: "Test Org", owner: @user)
    assert_equal "test-org-1", org2.slug
  end

  test "does not regenerate slug on update" do
    org = Organization.create!(name: "Original Name", owner: @user)
    original_slug = org.slug

    org.update!(name: "Updated Name")
    assert_equal original_slug, org.slug
  end

  test "allows manual slug assignment" do
    org = Organization.create!(name: "Test", slug: "custom-slug", owner: @user)
    assert_equal "custom-slug", org.slug
  end

  test "validates slug uniqueness" do
    Organization.create!(name: "First", slug: "unique-slug", owner: @user)

    org2 = Organization.new(name: "Second", slug: "unique-slug", owner: @user)
    assert_not org2.valid?
    assert_includes org2.errors[:slug], "has already been taken"
  end

  test "belongs to owner" do
    org = Organization.create!(name: "Test Org", owner: @user)
    assert_equal @user, org.owner
  end

  test "has many users through memberships" do
    org = Organization.create!(name: "Test Org", owner: @user)
    user2 = User.create!(
      email_address: "user2@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    OrganizationMembership.create!(user: @user, organization: org)
    OrganizationMembership.create!(user: user2, organization: org)

    assert_equal 2, org.users.count
    assert_includes org.users, @user
    assert_includes org.users, user2
  end

  test "destroys memberships when organization is destroyed" do
    org = Organization.create!(name: "Test Org", owner: @user)
    OrganizationMembership.create!(user: @user, organization: org)

    assert_difference "OrganizationMembership.count", -1 do
      org.destroy
    end
  end
end
