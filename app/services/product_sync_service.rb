# frozen_string_literal: true

# Product Sync Service
# Syncs merchant products to Stripe Product Catalog on connected account
class ProductSyncService
  class ProductSyncError < StandardError; end

  # Sync a product to Stripe
  # Creates or updates product and price on connected account
  # @param product [MerchantProduct] The product to sync
  # @return [Hash] Result with success status and Stripe objects
  def self.sync_product(product)
    new(product).sync_product
  end

  # Remove product from Stripe (archive)
  # @param product [MerchantProduct] The product to archive
  # @return [Hash] Result with success status
  def self.archive_product(product)
    new(product).archive_product
  end

  def initialize(product)
    @product = product
    @merchant = product.user
  end

  # Sync product to Stripe
  def sync_product
    validate_merchant!

    begin
      stripe_product = ensure_stripe_product
      stripe_price = ensure_stripe_price(stripe_product)

      @product.update(
        stripe_product_id: stripe_product.id,
        stripe_price_id: stripe_price.id
      )

      {
        success: true,
        stripe_product: stripe_product,
        stripe_price: stripe_price
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to sync product: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  # Archive product on Stripe
  def archive_product
    return { success: true } unless @product.stripe_product_id

    begin
      # Archive the product on Stripe
      Stripe::Product.update(
        @product.stripe_product_id,
        { active: false },
        { stripe_account: @merchant.merchant_processor.processor_id }
      )

      {
        success: true
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to archive product: #{e.message}"
      {
        success: false,
        error: e.message
      }
    end
  end

  private

  def validate_merchant!
    unless @merchant.merchant_onboarding_complete?
      raise ProductSyncError, "Merchant must complete Stripe Connect onboarding"
    end
  end

  # Ensure product exists on Stripe
  def ensure_stripe_product
    if @product.stripe_product_id
      # Update existing product
      Stripe::Product.update(
        @product.stripe_product_id,
        {
          name: @product.name,
          description: @product.description,
          active: @product.active,
          metadata: {
            merchant_product_id: @product.id
          }
        },
        { stripe_account: @merchant.merchant_processor.processor_id }
      )
    else
      # Create new product
      Stripe::Product.create(
        {
          name: @product.name,
          description: @product.description,
          active: @product.active,
          metadata: {
            merchant_product_id: @product.id
          }
        },
        { stripe_account: @merchant.merchant_processor.processor_id }
      )
    end
  end

  # Ensure price exists for product
  def ensure_stripe_price(stripe_product)
    if @product.stripe_price_id
      # Retrieve existing price
      Stripe::Price.retrieve(
        @product.stripe_price_id,
        { stripe_account: @merchant.merchant_processor.processor_id }
      )
    else
      # Create new price
      Stripe::Price.create(
        {
          product: stripe_product.id,
          unit_amount: @product.default_price_cents,
          currency: "usd",
          metadata: {
            merchant_product_id: @product.id
          }
        },
        { stripe_account: @merchant.merchant_processor.processor_id }
      )
    end
  end
end
