require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    sign_in_as @user

    # Create organizations
    @user_org = organizations(:one)
    @other_org = organizations(:two)

    # Ensure user is member of first org
    @user_org.organization_memberships.find_or_create_by!(user: @user, role: :admin)
  end

  test "should get index" do
    get organizations_url
    assert_response :success
    assert_select "h1", "Your Organizations"
  end

  test "index should show only user's organizations" do
    get organizations_url
    assert_response :success

    # Should show user's organization in the list
    assert_match @user_org.name, response.body

    # Should not show other user's organization if user is not a member
    unless @user.organizations.include?(@other_org)
      assert_no_match @other_org.name, response.body
    end
  end

  test "should get new" do
    get new_organization_url
    assert_response :success
    assert_select "h1", "Create New Organization"
  end

  test "should create organization and auto-switch to it" do
    assert_difference([ "Organization.count", "OrganizationMembership.count" ], 1) do
      post organizations_url, params: { organization: { name: "Test Org" } }
    end

    organization = Organization.find_by(name: "Test Org")
    assert_redirected_to organization_url(organization)

    # User should be owner and admin
    assert_equal @user, organization.owner
    assert organization.organization_memberships.exists?(user: @user, role: :admin)

    # Session should be switched to new organization
    follow_redirect!
    assert_equal organization.id.to_s, session[:current_organization_id]
  end

  test "should not create organization with invalid params" do
    assert_no_difference([ "Organization.count", "OrganizationMembership.count" ]) do
      post organizations_url, params: { organization: { name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "should get show for member organization" do
    get organization_url(@user_org)
    assert_response :success
  end

  test "should not show organization user is not member of" do
    # Ensure user is not member of other_org
    @other_org.organization_memberships.where(user: @user).destroy_all

    get organization_url(@other_org)
    assert_redirected_to organizations_url
    assert_equal "You don't have access to this organization.", flash[:alert]
  end

  test "should switch to member organization" do
    # Ensure user is member of both organizations
    @user_org.organization_memberships.find_or_create_by!(user: @user, role: :admin)
    @other_org.organization_memberships.find_or_create_by!(user: @user, role: :member)

    # Set current org to user_org
    post switch_organization_url(@user_org)

    # Switch to other_org
    post switch_organization_url(@other_org)
    assert_redirected_to root_path
    assert_equal "Switched to #{@other_org.name}", flash[:notice]

    # Session should be updated
    follow_redirect!
    assert_equal @other_org.id.to_s, session[:current_organization_id]
  end

  test "should not switch to non-member organization" do
    # Ensure user is not member of other_org
    @other_org.organization_memberships.where(user: @user).destroy_all

    post switch_organization_url(@other_org)
    assert_redirected_to root_path
    assert_equal "Unable to switch organizations.", flash[:alert]

    # Session should not be updated
    follow_redirect!
    assert_not_equal @other_org.id.to_s, session[:current_organization_id]
  end

  test "should require authentication for all actions" do
    sign_out

    get organizations_url
    assert_redirected_to signin_url

    get new_organization_url
    assert_redirected_to signin_url

    post organizations_url, params: { organization: { name: "Test" } }
    assert_redirected_to signin_url

    get organization_url(@user_org)
    assert_redirected_to signin_url

    post switch_organization_url(@user_org)
    assert_redirected_to signin_url
  end
end
