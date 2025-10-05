# frozen_string_literal: true

# Merchant Products Controller
# Handles CRUD operations for merchant product catalog
class MerchantProductsController < ApplicationController
  before_action :require_organization_context
  before_action :require_subscription
  before_action :set_product, only: [ :show, :edit, :update, :destroy, :archive, :unarchive ]

  # GET /products
  def index
    @products = Current.organization.merchant_products
                       .search(params[:query])
                       .recent
                       .limit(100)

    @active_products = Current.organization.merchant_products.active
    @inactive_products = Current.organization.merchant_products.inactive
  end

  # GET /products/:id
  def show
  end

  # GET /products/new
  def new
    @product = Current.organization.merchant_products.build
  end

  # GET /products/:id/edit
  def edit
  end

  # POST /products
  def create
    @product = Current.organization.merchant_products.build(product_params)

    if @product.save
      redirect_to products_path, notice: "Product created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /products/:id
  def update
    if @product.update(product_params)
      redirect_to products_path, notice: "Product updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    if @product.invoice_items.any?
      redirect_to products_path, alert: "Cannot delete product that has been used in invoices. Archive it instead."
    else
      @product.destroy
      redirect_to products_path, notice: "Product deleted successfully."
    end
  end

  # PATCH /products/:id/archive
  def archive
    @product.archive!
    redirect_to products_path, notice: "Product archived successfully."
  end

  # PATCH /products/:id/unarchive
  def unarchive
    @product.unarchive!
    redirect_to products_path, notice: "Product activated successfully."
  end

  private

  def set_product
    @product = Current.organization.merchant_products.find(params[:id])
  end

  def product_params
    params.require(:merchant_product).permit(
      :name,
      :description,
      :default_price_dollars,
      :unit_type,
      :tax_code,
      :active
    )
  end

  def require_subscription
    unless Current.organization.on_trial_or_subscribed?
      redirect_to pricing_path, alert: "You need an active subscription to manage products."
    end
  end
end
