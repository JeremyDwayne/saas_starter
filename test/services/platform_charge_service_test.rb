require "test_helper"

class PlatformChargeServiceTest < ActiveSupport::TestCase
  def setup
    @merchant = users(:one)
  end

  test "should raise OnboardingIncompleteError when merchant not onboarded" do
    error = assert_raises(PlatformChargeService::OnboardingIncompleteError) do
      PlatformChargeService.create_charge(
        merchant: @merchant,
        amount_cents: 10000,
        customer_email: "customer@example.com"
      )
    end

    assert_equal "Merchant must complete Stripe Connect onboarding", error.message
  end
end
