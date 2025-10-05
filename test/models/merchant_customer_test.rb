require "test_helper"

class MerchantCustomerTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @organization = Organization.create!(owner: @user, name: "Test Organization")
    OrganizationMembership.create!(user: @user, organization: @organization, role: :admin)
    @customer = MerchantCustomer.create!(
      user: @user,
      organization: @organization,
      name: "Acme Corporation",
      email: "billing@acme.com",
      country: "US"
    )
  end

  test "valid customer" do
    assert @customer.valid?
  end

  test "requires name" do
    @customer.name = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:name], "can't be blank"
  end

  test "requires email" do
    @customer.email = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:email], "can't be blank"
  end

  test "requires country" do
    @customer.country = nil
    assert_not @customer.valid?
    assert_includes @customer.errors[:country], "can't be blank"
  end

  test "full_address formats address correctly" do
    customer = MerchantCustomer.new(
      user: @user,
      organization: @organization,
      name: "Test Customer",
      email: "test@example.com",
      address_line1: "123 Main St",
      address_line2: "Apt 4B",
      city: "San Francisco",
      state: "CA",
      postal_code: "94102",
      country: "US"
    )

    expected = "123 Main St\nApt 4B\nSan Francisco, CA\n94102\nUS"
    assert_equal expected, customer.full_address
  end

  test "full_address handles missing fields" do
    customer = MerchantCustomer.new(
      user: @user,
      organization: @organization,
      name: "Test Customer",
      email: "test@example.com",
      address_line1: "123 Main St",
      city: "San Francisco",
      country: "US"
    )

    expected = "123 Main St\nSan Francisco\nUS"
    assert_equal expected, customer.full_address
  end

  test "search scope finds by name" do
    results = MerchantCustomer.search("Acme")
    assert_includes results, @customer
  end

  test "search scope finds by email" do
    results = MerchantCustomer.search(@customer.email)
    assert_includes results, @customer
  end

  test "recent scope orders by created_at desc" do
    older = MerchantCustomer.create!(
      user: @user,
      organization: @organization,
      name: "Older Customer",
      email: "older@example.com",
      country: "US"
    )

    newer = MerchantCustomer.create!(
      user: @user,
      organization: @organization,
      name: "Newer Customer",
      email: "newer@example.com",
      country: "US"
    )

    results = MerchantCustomer.recent
    assert_equal newer, results.first
  end
end
