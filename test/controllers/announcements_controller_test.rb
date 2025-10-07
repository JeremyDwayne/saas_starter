require "test_helper"

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get announcements_url
    assert_response :success
  end

  test "index should only show published announcements" do
    get announcements_url
    assert_response :success

    # Should show published announcements
    assert_select "h2", text: /New Dashboard Analytics/
    assert_select "h2", text: /Updated Billing System/

    # Should not show unpublished announcements
    assert_select "h2", text: /Upcoming Feature/, count: 0
  end

  test "should show published announcement" do
    announcement = announcements(:published_new_feature)
    get announcement_url(announcement)
    assert_response :success
    assert_select "h1", text: announcement.title
  end

  test "should not access unpublished announcement" do
    announcement = announcements(:unpublished)
    get announcement_url(announcement)
    assert_response :not_found
  end

  test "index should display badge colors for different types" do
    get announcements_url
    assert_response :success

    # Check that badges are rendered (they should have the badge color classes)
    assert_select "span.bg-green-100" # new_feature badge
    assert_select "span.bg-blue-100"  # update badge
  end
end
