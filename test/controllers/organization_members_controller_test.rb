require "test_helper"

class OrganizationMembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = Organization.create!(owner: @user, name: "Test Organization")
    OrganizationMembership.create!(user: @user, organization: @organization, role: :admin)
    sign_in_as @user
  end

  test "should get index" do
    get organization_members_url(@organization)
    assert_response :success
  end

  test "should update member role" do
    member_user = User.create!(email_address: "member@example.com", password: "password123")
    membership = OrganizationMembership.create!(user: member_user, organization: @organization, role: :member)

    patch organization_member_url(@organization, membership), params: { organization_membership: { role: :admin } }
    assert_redirected_to organization_members_path(@organization)
    assert_equal "admin", membership.reload.role
  end

  test "should destroy member" do
    member_user = User.create!(email_address: "member@example.com", password: "password123")
    membership = OrganizationMembership.create!(user: member_user, organization: @organization, role: :member)

    assert_difference("OrganizationMembership.count", -1) do
      delete organization_member_url(@organization, membership)
    end
    assert_redirected_to organization_members_path(@organization)
  end
end
