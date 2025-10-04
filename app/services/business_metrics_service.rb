# Service to calculate key business metrics for the admin dashboard
class BusinessMetricsService
  def call
    {
      # Revenue metrics
      mrr: monthly_recurring_revenue,
      arr: annual_recurring_revenue,
      total_revenue: total_revenue,
      revenue_this_month: revenue_this_month,
      revenue_last_month: revenue_last_month,
      revenue_growth_rate: revenue_growth_rate,

      # Subscription metrics
      active_subscriptions: active_subscriptions_count,
      trial_subscriptions: trial_subscriptions_count,
      total_customers: total_customers_count,
      new_customers_this_month: new_customers_this_month,
      churn_rate: churn_rate,

      # Platform metrics (Stripe Connect)
      platform_revenue: platform_revenue,
      platform_revenue_this_month: platform_revenue_this_month,
      total_transactions: total_platform_transactions,

      # Customer metrics
      ltv: lifetime_value,
      cac: customer_acquisition_cost,
      ltv_cac_ratio: ltv_cac_ratio,
      average_revenue_per_user: average_revenue_per_user,

      # Referral metrics
      total_referral_credits: total_referral_credits,
      referral_credits_used: referral_credits_used,
      successful_referrals: successful_referrals_count
    }
  end

  private

  # Revenue Metrics

  def monthly_recurring_revenue
    # MRR = sum of all active subscription amounts
    active_subs = Pay::Subscription.active.includes(:customer)

    mrr_cents = active_subs.sum do |sub|
      # Get the subscription amount from Stripe data
      sub.data&.dig("plan", "amount") || 0
    end

    format_cents(mrr_cents)
  end

  def annual_recurring_revenue
    # ARR = MRR * 12
    mrr = monthly_recurring_revenue
    mrr[:cents] * 12
  end

  def total_revenue
    # Total revenue from all successful charges
    total_cents = Pay::Charge.where(
      type: "Pay::Stripe::Charge"
    ).sum(:amount)

    format_cents(total_cents)
  end

  def revenue_this_month
    start_of_month = Time.current.beginning_of_month
    total_cents = Pay::Charge.where(
      type: "Pay::Stripe::Charge"
    ).where("created_at >= ?", start_of_month).sum(:amount)

    format_cents(total_cents)
  end

  def revenue_last_month
    start_of_last_month = 1.month.ago.beginning_of_month
    end_of_last_month = 1.month.ago.end_of_month

    total_cents = Pay::Charge.where(
      type: "Pay::Stripe::Charge"
    ).where(created_at: start_of_last_month..end_of_last_month).sum(:amount)

    format_cents(total_cents)
  end

  def revenue_growth_rate
    this_month = revenue_this_month[:cents]
    last_month = revenue_last_month[:cents]

    return 0 if last_month.zero?

    ((this_month - last_month).to_f / last_month * 100).round(2)
  end

  # Subscription Metrics

  def active_subscriptions_count
    Pay::Subscription.active.count
  end

  def trial_subscriptions_count
    Pay::Subscription.on_trial.count
  end

  def total_customers_count
    User.count
  end

  def new_customers_this_month
    User.where("created_at >= ?", Time.current.beginning_of_month).count
  end

  def churn_rate
    # Churn rate = (subscriptions canceled this month / active subscriptions at start of month) * 100
    start_of_month = Time.current.beginning_of_month

    # Count subscriptions that ended this month
    churned = Pay::Subscription.where(
      "ends_at >= ? AND ends_at < ?",
      start_of_month,
      Time.current
    ).count

    # Total active at start of month
    active_at_start = Pay::Subscription.where(
      "created_at < ?",
      start_of_month
    ).active.count

    return 0 if active_at_start.zero?

    ((churned.to_f / active_at_start) * 100).round(2)
  end

  # Platform Metrics (Stripe Connect)

  def platform_revenue
    # Total platform fees collected
    total_cents = PlatformTransaction.where(status: "succeeded").sum(:application_fee_cents)
    format_cents(total_cents)
  end

  def platform_revenue_this_month
    start_of_month = Time.current.beginning_of_month
    total_cents = PlatformTransaction.where(status: "succeeded")
      .where("created_at >= ?", start_of_month)
      .sum(:application_fee_cents)

    format_cents(total_cents)
  end

  def total_platform_transactions
    PlatformTransaction.where(status: "succeeded").count
  end

  # Customer Value Metrics

  def lifetime_value
    # LTV = Average Revenue Per User * Average Customer Lifespan (in months)
    # Simplified: Total revenue / Total customers who have ever paid
    paying_customers = Pay::Charge.where(type: "Pay::Stripe::Charge")
      .distinct
      .count(:customer_id)

    return format_cents(0) if paying_customers.zero?

    avg_revenue_cents = total_revenue[:cents] / paying_customers

    # Estimate average lifespan based on churn
    # Average lifespan (months) = 1 / (monthly churn rate / 100)
    monthly_churn = churn_rate / 100.0
    avg_lifespan = monthly_churn > 0 ? (1 / monthly_churn) : 24 # Default to 24 months if no churn

    ltv_cents = (avg_revenue_cents * avg_lifespan).round

    format_cents(ltv_cents)
  end

  def customer_acquisition_cost
    # CAC = Total Sales & Marketing Spend / Number of New Customers
    # Note: This is a placeholder - you'll need to track actual marketing spend
    # For now, we'll use a simple calculation based on referral credits as proxy

    new_customers = new_customers_this_month
    return format_cents(0) if new_customers.zero?

    # Using referral credits as a proxy for acquisition cost
    credits_this_month = ReferralReward.where(
      "created_at >= ?",
      Time.current.beginning_of_month
    ).sum(:amount)

    cac_cents = new_customers > 0 ? (credits_this_month / new_customers) : 0

    format_cents(cac_cents)
  end

  def ltv_cac_ratio
    ltv = lifetime_value[:cents]
    cac = customer_acquisition_cost[:cents]

    return 0 if cac.zero?

    (ltv.to_f / cac).round(2)
  end

  def average_revenue_per_user
    total = total_revenue[:cents]
    customers = total_customers_count

    return format_cents(0) if customers.zero?

    format_cents(total / customers)
  end

  # Referral Metrics

  def total_referral_credits
    format_cents(ReferralReward.sum(:amount))
  end

  def referral_credits_used
    format_cents(ReferralReward.used.sum(:amount))
  end

  def successful_referrals_count
    ReferralReward.where.not(status: "pending").count
  end

  # Helper Methods

  def format_cents(cents)
    {
      cents: cents,
      dollars: (cents / 100.0).round(2),
      formatted: format("$%.2f", cents / 100.0)
    }
  end
end
