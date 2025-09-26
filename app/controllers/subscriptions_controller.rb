class SubscriptionsController < ApplicationController
  def create
    plan_id = params[:plan_id]
    billing_cycle = params[:billing_cycle] || "month"
    trial_days = 14

    # Define plan configurations with Stripe Price IDs
    # In production, create these prices in your Stripe Dashboard
    plans = {
      "personal" => {
        "month" => { amount: 900, interval: "month" },
        "year" => { amount: 8600, interval: "year" }
      },
      "professional" => {
        "month" => { amount: 2900, interval: "month" },
        "year" => { amount: 27800, interval: "year" }
      },
      "enterprise" => {
        "month" => { amount: 9900, interval: "month" },
        "year" => { amount: 95000, interval: "year" }
      }
    }

    unless plans[plan_id] && plans[plan_id][billing_cycle]
      redirect_to pricing_path, alert: "Invalid plan selected"
      return
    end

    plan_config = plans[plan_id][billing_cycle]

    begin
      # Set up Stripe as payment processor
      Current.user.set_payment_processor(:stripe)

      # Create or find Stripe Price for the plan
      price = create_stripe_price(plan_id, plan_config)

      # Create Stripe Checkout Session using Pay gem
      checkout_session = Current.user.payment_processor.checkout(
        mode: "subscription",
        line_items: [ {
          price: price.id,
          quantity: 1
        } ],
        subscription_data: {
          trial_period_days: trial_days,
          metadata: {
            pay_name: plan_id
          }
        }
      )

      # Redirect to Stripe Checkout
      redirect_to checkout_session.url, allow_other_host: true, status: :see_other

    rescue => e
      Rails.logger.error "Checkout session creation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to pricing_path, alert: "Unable to start checkout. Please try again."
    end
  end

  def success
    # This page is reached after successful Stripe checkout
    # The subscription is automatically created by Pay gem webhooks
    flash[:notice] = "Welcome aboard! Your subscription is now active."
    redirect_to dashboard_path
  end

  def cancel
    # This is reached when user cancels checkout
    redirect_to pricing_path, notice: "Checkout cancelled. Feel free to try again anytime!"
  end

  def cancel_subscription
    if Current.user.subscribed?
      Current.user.subscription.cancel
      flash[:notice] = "Your subscription has been cancelled successfully."
    else
      flash[:alert] = "No active subscription found."
    end

    redirect_to dashboard_path
  end

  private

  def create_stripe_price(plan_id, plan_config)
    puts "Creating Stripe Price for #{plan_id} with amount #{plan_config[:amount]} and interval #{plan_config[:interval]}"
    # First create or find the product
    product_name = "#{plan_id.capitalize} Plan"
    product = find_or_create_stripe_product(product_name)

    # Create the price
    Stripe::Price.create({
      product: product.id,
      unit_amount: plan_config[:amount],
      currency: "usd",
      recurring: {
        interval: plan_config[:interval]
      },
      metadata: {
        plan_id: plan_id,
        billing_cycle: plan_config[:interval]
      }
    })
  end

  def find_or_create_stripe_product(name)
    # Try to find existing product
    products = Stripe::Product.list(limit: 100)
    existing_product = products.data.find { |product| product.name == name }

    return existing_product if existing_product

    # Create new product if not found
    Stripe::Product.create({
      name: name,
      description: "#{name} subscription"
    })
  end
end
