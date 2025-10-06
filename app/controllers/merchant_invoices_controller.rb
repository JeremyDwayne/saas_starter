# frozen_string_literal: true

# Merchant Invoices Controller
# Handles CRUD operations and actions for merchant invoices
class MerchantInvoicesController < ApplicationController
  layout "dashboard"
  before_action :require_organization_context
  before_action :require_subscription
  before_action :require_merchant_onboarded, except: [ :index, :show ]
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :send_invoice, :mark_paid, :void ]

  # GET /invoices
  def index
    @invoices = Current.organization.merchant_invoices
                       .includes(:customer)
                       .recent
                       .limit(100)

    # Filter by status if provided
    @invoices = @invoices.where(status: params[:status]) if params[:status].present?

    # Summary stats
    @draft_count = Current.organization.merchant_invoices.draft.count
    @open_count = Current.organization.merchant_invoices.open.count
    @paid_count = Current.organization.merchant_invoices.paid.count
    @overdue_count = Current.organization.merchant_invoices.overdue.count
    @total_outstanding = Current.organization.merchant_invoices.unpaid.sum(:total_cents)
  end

  # GET /invoices/:id
  def show
  end

  # GET /invoices/new
  def new
    @invoice = Current.organization.merchant_invoices.build
    @invoice.invoice_items.build # Start with one line item
    @customers = Current.organization.merchant_customers.order(:name)
    @products = Current.organization.merchant_products.active.order(:name)
  end

  # GET /invoices/:id/edit
  def edit
    @customers = Current.organization.merchant_customers.order(:name)
    @products = Current.organization.merchant_products.active.order(:name)
  end

  # POST /invoices
  def create
    @invoice = Current.organization.merchant_invoices.build(invoice_params)

    if @invoice.save
      redirect_to invoice_path(@invoice), notice: "Invoice created successfully."
    else
      @customers = Current.organization.merchant_customers.order(:name)
      @products = Current.organization.merchant_products.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /invoices/:id
  def update
    if @invoice.draft? && @invoice.update(invoice_params)
      redirect_to invoice_path(@invoice), notice: "Invoice updated successfully."
    else
      @customers = Current.organization.merchant_customers.order(:name)
      @products = Current.organization.merchant_products.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /invoices/:id
  def destroy
    if @invoice.draft?
      @invoice.destroy
      redirect_to invoices_path, notice: "Invoice deleted successfully."
    else
      redirect_to invoice_path(@invoice), alert: "Only draft invoices can be deleted."
    end
  end

  # POST /invoices/:id/send_invoice
  def send_invoice
    if @invoice.draft?
      # Calculate application fee before sending
      @invoice.calculate_application_fee
      @invoice.save

      # Use InvoiceService to create on Stripe and send
      result = InvoiceService.send_invoice(@invoice)

      if result[:success]
        @invoice.mark_as_sent!
        redirect_to invoice_path(@invoice), notice: "Invoice sent successfully!"
      else
        redirect_to invoice_path(@invoice), alert: "Failed to send invoice: #{result[:error]}"
      end
    else
      redirect_to invoice_path(@invoice), alert: "Only draft invoices can be sent."
    end
  end

  # POST /invoices/:id/mark_paid
  def mark_paid
    if @invoice.open?
      @invoice.mark_as_paid!
      redirect_to invoice_path(@invoice), notice: "Invoice marked as paid."
    else
      redirect_to invoice_path(@invoice), alert: "Only open invoices can be marked as paid."
    end
  end

  # POST /invoices/:id/void
  def void
    if @invoice.open? || @invoice.draft?
      # Void on Stripe if it was sent
      InvoiceService.void_invoice(@invoice) if @invoice.stripe_invoice_id.present?

      @invoice.mark_as_void!
      redirect_to invoice_path(@invoice), notice: "Invoice voided successfully."
    else
      redirect_to invoice_path(@invoice), alert: "Only open or draft invoices can be voided."
    end
  end

  private

  def set_invoice
    @invoice = Current.organization.merchant_invoices.includes(:customer, :invoice_items).find(params[:id])
  end

  def invoice_params
    params.require(:merchant_invoice).permit(
      :customer_id,
      :days_until_due,
      :notes,
      :footer_text,
      invoice_items_attributes: [ :id, :product_id, :description, :quantity, :unit_price_dollars, :_destroy ]
    )
  end

  def require_subscription
    unless Current.organization.on_trial_or_subscribed?
      redirect_to pricing_path, alert: "You need an active subscription to manage invoices."
    end
  end

  def require_merchant_onboarded
    unless Current.organization.merchant_onboarding_complete?
      redirect_to new_connected_account_path,
                  alert: "Please complete Stripe Connect onboarding before creating invoices."
    end
  end
end
