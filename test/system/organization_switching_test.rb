require "application_system_test_case"

class OrganizationSwitchingTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)

    # Create two organizations for the user
    @org1 = Organization.create!(name: "First Organization", owner: @user)
    @org2 = Organization.create!(name: "Second Organization", owner: @user)

    # Create memberships for the user
    @org1.organization_memberships.create!(user: @user, role: :admin)
    @org2.organization_memberships.create!(user: @user, role: :admin)
  end

  test "user can see both organizations in dropdown after login" do
    # Sign in
    visit signin_path
    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"

    # Should be redirected to root
    assert_current_path root_path

    # Click organization switcher dropdown
    find("button", text: @org1.name).click

    # Should see both organizations in dropdown menu
    within "[data-dropdown-target='menu']" do
      assert_text "Current Organization"
      assert_text @org1.name
      assert_text @org2.name
    end
  end

  test "user can switch between organizations" do
    # Sign in
    visit signin_path
    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"

    # Open dropdown and switch
    find("button", text: @org1.name).click
    within "[data-dropdown-target='menu']" do
      click_button "Switch", match: :first
    end

    # Should see success message
    assert_text "Switched to #{@org2.name}"

    # Dropdown button should now show the new organization
    assert_selector "button", text: @org2.name
  end

  test "page content updates after switching organizations" do
    # Sign in
    visit signin_path
    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"

    # Navigate to organizations index
    visit organizations_path

    # Click switch button
    within "li", text: @org2.name do
      click_button "Switch"
    end

    # Should redirect and show switch message
    assert_text "Switched to #{@org2.name}"

    # Return to organizations index
    visit organizations_path

    # Org2 should now be marked as Current
    within "li", text: @org2.name do
      assert_text "Current"
    end

    within "li", text: @org1.name do
      assert_no_text "Current"
    end
  end

  test "organization switcher shows manage and create options" do
    # Sign in
    visit signin_path
    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"

    # Open dropdown
    find("button", text: @org1.name).click

    # Should see management links
    within "[data-dropdown-target='menu']" do
      assert_link "Manage Organizations", href: organizations_path
      assert_link "Create Organization", href: new_organization_path
    end
  end

  test "user with one organization sees create option" do
    # Remove user from org2
    @org2.organization_memberships.where(user: @user).destroy_all

    # Sign in
    visit signin_path
    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"

    # Open dropdown
    find("button", text: @org1.name).click

    # Should see "No other organizations" message
    within "[data-dropdown-target='menu']" do
      assert_text "No other organizations"
      assert_link "Create Organization", href: new_organization_path
    end
  end

  test "organization context persists across page navigation" do
    # Sign in
    visit signin_path
    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"

    # Verify org1 is current
    assert_selector "button", text: @org1.name

    # Navigate to different pages
    visit dashboard_path
    assert_selector "button", text: @org1.name

    visit pricing_path
    assert_selector "button", text: @org1.name

    visit settings_path
    assert_selector "button", text: @org1.name
  end
end
