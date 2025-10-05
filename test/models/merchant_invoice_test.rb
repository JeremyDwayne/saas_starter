require "test_helper"

class MerchantInvoiceTest < ActiveSupport::TestCase
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
    @invoice = MerchantInvoice.create!(
      user: @user,
      organization: @organization,
      customer: @customer,
      invoice_number: "000001",
      status: "draft",
      subtotal_cents: 15000,
      tax_cents: 0,
      total_cents: 15000,
      application_fee_cents: 0,
      days_until_due: 30
    )
  end

  test "valid invoice" do
    assert @invoice.valid?
  end

  test "generates invoice number on create" do
    # Clear existing invoices to avoid number collision
    @user.invoices.destroy_all

    invoice = MerchantInvoice.new(
      user: @user,
      organization: @organization,
      customer: @customer,
      status: "draft",
      days_until_due: 30
    )

    assert_nil invoice.invoice_number
    invoice.save!
    assert_not_nil invoice.invoice_number
    assert_match /\d{6}/, invoice.invoice_number
  end

  test "generates sequential invoice numbers" do
    # Clear existing invoices to avoid number collision
    @user.invoices.destroy_all

    invoice1 = MerchantInvoice.create!(
      user: @user,
      organization: @organization,
      customer: @customer,
      status: "draft",
      days_until_due: 30
    )

    invoice2 = MerchantInvoice.create!(
      user: @user,
      organization: @organization,
      customer: @customer,
      status: "draft",
      days_until_due: 30
    )

    assert_equal invoice1.invoice_number.to_i + 1, invoice2.invoice_number.to_i
  end

  test "validates status inclusion" do
    @invoice.status = "invalid"
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:status], "is not included in the list"
  end

  test "calculates totals from line items" do
    @invoice.invoice_items.create!(
      description: "Item 1",
      quantity: 2,
      unit_price_cents: 5000,
      amount_cents: 10000
    )

    @invoice.invoice_items.create!(
      description: "Item 2",
      quantity: 1,
      unit_price_cents: 7500,
      amount_cents: 7500
    )

    @invoice.calculate_totals
    assert_equal 17500, @invoice.subtotal_cents
    assert_equal 17500, @invoice.total_cents
  end

  test "draft? returns true for draft status" do
    @invoice.status = "draft"
    assert @invoice.draft?
  end

  test "open? returns true for open status" do
    @invoice.status = "open"
    assert @invoice.open?
  end

  test "paid? returns true for paid status" do
    @invoice.status = "paid"
    assert @invoice.paid?
  end

  test "void? returns true for void status" do
    @invoice.status = "void"
    assert @invoice.void?
  end

  test "overdue? returns true when open and past due date" do
    @invoice.status = "open"
    @invoice.due_date = Date.yesterday
    assert @invoice.overdue?
  end

  test "overdue? returns false when not past due date" do
    @invoice.status = "open"
    @invoice.due_date = Date.tomorrow
    assert_not @invoice.overdue?
  end

  test "mark_as_sent! updates status and sent_at" do
    @invoice.mark_as_sent!
    assert_equal "open", @invoice.status
    assert_not_nil @invoice.sent_at
  end

  test "mark_as_paid! updates status and paid_at" do
    @invoice.mark_as_paid!
    assert_equal "paid", @invoice.status
    assert_not_nil @invoice.paid_at
  end

  test "mark_as_void! updates status and voided_at" do
    @invoice.mark_as_void!
    assert_equal "void", @invoice.status
    assert_not_nil @invoice.voided_at
  end

  test "dollar amount helpers" do
    @invoice.subtotal_cents = 10000
    @invoice.tax_cents = 1000
    @invoice.total_cents = 11000
    @invoice.application_fee_cents = 550

    assert_equal 100.0, @invoice.subtotal_dollars
    assert_equal 10.0, @invoice.tax_dollars
    assert_equal 110.0, @invoice.total_dollars
    assert_equal 5.5, @invoice.application_fee_dollars
  end

  test "draft scope returns only draft invoices" do
    draft = @invoice
    open_invoice = MerchantInvoice.create!(
      user: @user,
      organization: @organization,
      customer: @customer,
      invoice_number: "000002",
      status: "open",
      subtotal_cents: 50000,
      tax_cents: 0,
      total_cents: 50000,
      application_fee_cents: 2500,
      days_until_due: 30
    )

    results = MerchantInvoice.draft
    assert_includes results, draft
    assert_not_includes results, open_invoice
  end

  test "open scope returns only open invoices" do
    open_invoice = MerchantInvoice.create!(
      user: @user,
      organization: @organization,
      customer: @customer,
      invoice_number: "000002",
      status: "open",
      subtotal_cents: 50000,
      tax_cents: 0,
      total_cents: 50000,
      application_fee_cents: 2500,
      days_until_due: 30
    )
    draft = @invoice

    results = MerchantInvoice.open
    assert_includes results, open_invoice
    assert_not_includes results, draft
  end

  test "unpaid scope returns draft and open invoices" do
    draft = @invoice
    open_invoice = MerchantInvoice.create!(
      user: @user,
      organization: @organization,
      customer: @customer,
      invoice_number: "000002",
      status: "open",
      subtotal_cents: 50000,
      tax_cents: 0,
      total_cents: 50000,
      application_fee_cents: 2500,
      days_until_due: 30
    )
    paid_invoice = MerchantInvoice.create!(
      user: @user,
      organization: @organization,
      customer: @customer,
      invoice_number: "000003",
      status: "paid",
      subtotal_cents: 75000,
      tax_cents: 0,
      total_cents: 75000,
      application_fee_cents: 3750,
      days_until_due: 30
    )

    results = MerchantInvoice.unpaid
    assert_includes results, draft
    assert_includes results, open_invoice
    assert_not_includes results, paid_invoice
  end
end
