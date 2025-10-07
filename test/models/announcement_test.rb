require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  test "should be valid with required attributes" do
    announcement = Announcement.new(
      title: "Test Announcement",
      body: "This is a test announcement body.",
      announcement_type: :new_feature
    )
    assert announcement.valid?
  end

  test "should require title" do
    announcement = Announcement.new(body: "Test", announcement_type: :new_feature)
    assert_not announcement.valid?
    assert_includes announcement.errors[:title], "can't be blank"
  end

  test "should require body" do
    announcement = Announcement.new(title: "Test", announcement_type: :new_feature)
    assert_not announcement.valid?
    assert_includes announcement.errors[:body], "can't be blank"
  end

  test "published scope should only return published announcements" do
    published_count = Announcement.published.count
    assert_equal 4, published_count # We have 4 published in fixtures

    unpublished = announcements(:unpublished)
    assert_not Announcement.published.include?(unpublished)
  end

  test "unpublished scope should only return unpublished announcements" do
    unpublished_count = Announcement.unpublished.count
    assert_equal 1, unpublished_count

    published = announcements(:published_new_feature)
    assert_not Announcement.unpublished.include?(published)
  end

  test "published? should return true for published announcements" do
    announcement = announcements(:published_new_feature)
    assert announcement.published?
  end

  test "published? should return false for unpublished announcements" do
    announcement = announcements(:unpublished)
    assert_not announcement.published?
  end

  test "publish! should set published_at to current time" do
    announcement = Announcement.create!(
      title: "Draft",
      body: "Draft body",
      announcement_type: :new_feature
    )

    assert_nil announcement.published_at
    assert_not announcement.published?

    announcement.publish!
    announcement.reload

    assert_not_nil announcement.published_at
    assert announcement.published?
  end

  test "badge_color should return correct class for new_feature" do
    announcement = announcements(:published_new_feature)
    assert_equal "bg-green-100 text-green-800", announcement.badge_color
  end

  test "badge_color should return correct class for update" do
    announcement = announcements(:published_update)
    assert_equal "bg-blue-100 text-blue-800", announcement.badge_color
  end

  test "badge_color should return correct class for improvement" do
    announcement = announcements(:published_improvement)
    assert_equal "bg-purple-100 text-purple-800", announcement.badge_color
  end

  test "badge_color should return correct class for fix" do
    announcement = announcements(:published_fix)
    assert_equal "bg-orange-100 text-orange-800", announcement.badge_color
  end

  test "type_label should return human-readable labels" do
    assert_equal "New", announcements(:published_new_feature).type_label
    assert_equal "Update", announcements(:published_update).type_label
    assert_equal "Improvement", announcements(:published_improvement).type_label
    assert_equal "Fix", announcements(:published_fix).type_label
  end

  test "recent scope should order by published_at descending" do
    announcements = Announcement.published.recent
    dates = announcements.map(&:published_at)

    # Verify dates are in descending order
    assert_equal dates, dates.sort.reverse
  end
end
