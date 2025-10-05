# frozen_string_literal: true

# Merchant Customers Controller
# Handles CRUD operations for merchant customer management
class MerchantCustomersController < ApplicationController
  before_action :require_subscription
  before_action :set_customer, only: [ :show, :edit, :update, :destroy ]

  # GET /customers
  def index
    @customers = Current.user.customers
                        .search(params[:query])
                        .recent
                        .page(params[:page])
                        .per(20)
  end

  # GET /customers/:id
  def show
    @invoices = @customer.invoices.recent.limit(10)
  end

  # GET /customers/new
  def new
    @customer = Current.user.customers.build(country: "US")
  end

  # GET /customers/:id/edit
  def edit
  end

  # POST /customers
  def create
    @customer = Current.user.customers.build(customer_params)

    if @customer.save
      redirect_to customers_path, notice: "Customer created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /customers/:id
  def update
    if @customer.update(customer_params)
      redirect_to customer_path(@customer), notice: "Customer updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /customers/:id
  def destroy
    if @customer.invoices.any?
      redirect_to customers_path, alert: "Cannot delete customer with existing invoices."
    else
      @customer.destroy
      redirect_to customers_path, notice: "Customer deleted successfully."
    end
  end

  private

  def set_customer
    @customer = Current.user.customers.find(params[:id])
  end

  def customer_params
    params.require(:merchant_customer).permit(
      :name,
      :email,
      :phone,
      :address_line1,
      :address_line2,
      :city,
      :state,
      :postal_code,
      :country,
      :notes
    )
  end

  def require_subscription
    unless Current.user.on_trial_or_subscribed?
      redirect_to pricing_path, alert: "You need an active subscription to manage customers."
    end
  end
end
