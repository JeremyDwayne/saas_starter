require "test_helper"

class MerchantProductTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @product = merchant_products(:consulting)
  end

  test "valid product" do
    assert @product.valid?
  end

  test "requires name" do
    @product.name = nil
    assert_not @product.valid?
    assert_includes @product.errors[:name], "can't be blank"
  end

  test "requires default_price_cents" do
    @product.default_price_cents = nil
    assert_not @product.valid?
    assert_includes @product.errors[:default_price_cents], "can't be blank"
  end

  test "requires positive price" do
    @product.default_price_cents = 0
    assert_not @product.valid?
    assert_includes @product.errors[:default_price_cents], "must be greater than 0"
  end

  test "requires unit_type" do
    @product.unit_type = nil
    assert_not @product.valid?
    assert_includes @product.errors[:unit_type], "can't be blank"
  end

  test "validates unit_type inclusion" do
    @product.unit_type = "invalid"
    assert_not @product.valid?
    assert_includes @product.errors[:unit_type], "is not included in the list"
  end

  test "default_price_dollars converts cents to dollars" do
    @product.default_price_cents = 15000
    assert_equal 150.0, @product.default_price_dollars
  end

  test "default_price_dollars= converts dollars to cents" do
    @product.default_price_dollars = 250.50
    assert_equal 25050, @product.default_price_cents
  end

  test "price_with_unit formats price correctly" do
    @product.default_price_cents = 10000
    @product.unit_type = "hour"
    assert_equal "$100.00 / hour", @product.price_with_unit
  end

  test "archive! sets active to false" do
    @product.archive!
    assert_not @product.active?
  end

  test "unarchive! sets active to true" do
    @product.update(active: false)
    @product.unarchive!
    assert @product.active?
  end

  test "active scope returns only active products" do
    active_product = @product
    inactive_product = merchant_products(:archived_service)
    inactive_product.update(active: false)

    results = MerchantProduct.active
    assert_includes results, active_product
    assert_not_includes results, inactive_product
  end

  test "inactive scope returns only inactive products" do
    active_product = @product
    inactive_product = merchant_products(:archived_service)
    inactive_product.update(active: false)

    results = MerchantProduct.inactive
    assert_includes results, inactive_product
    assert_not_includes results, active_product
  end

  test "search scope finds by name" do
    results = MerchantProduct.search("Consulting")
    assert_includes results, @product
  end

  test "search scope finds by description" do
    @product.update(description: "Expert web development")
    results = MerchantProduct.search("development")
    assert_includes results, @product
  end
end
