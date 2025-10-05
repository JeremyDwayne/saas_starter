# Platform charges controller
# Handles creating charges and viewing transaction history
class PlatformChargesController < ApplicationController
  before_action :require_organization_context
  before_action :require_subscription
  before_action :require_merchant_onboarded, except: [ :index, :show ]

  # GET /charges/new
  # Show charge creation form with fee preview
  def new
    @fee_calculation = FeeCalculationService.calculate_for_organization(
      Current.organization,
      params[:amount_cents]&.to_i || 1000
    )
  end

  # POST /charges
  # Create a new charge via PlatformChargeService
  def create
    result = PlatformChargeService.create_charge(
      merchant: Current.organization,
      amount_cents: charge_params[:amount_cents].to_i,
      customer_email: charge_params[:customer_email],
      description: charge_params[:description],
      metadata: charge_params[:metadata] || {}
    )

    flash[:notice] = "Payment successful! Fee: $#{result[:fee_calculation][:fee_cents] / 100.0}"
    redirect_to charges_path
  rescue PlatformChargeService::ChargeError => e
    flash[:alert] = "Payment failed: #{e.message}"
    redirect_to new_charge_path
  rescue PlatformChargeService::OnboardingIncompleteError => e
    redirect_to new_connected_account_path, alert: e.message
  rescue PlatformChargeService::SubscriptionRequiredError => e
    redirect_to pricing_path, alert: e.message
  end

  # GET /charges
  # Show transaction history with summary stats
  def index
    @transactions = Current.organization.platform_transactions.recent.limit(50)

    # Summary stats
    @total_revenue = Current.organization.platform_transactions.succeeded.sum(:charge_amount_cents)
    @total_fees = Current.organization.platform_transactions.succeeded.sum(:application_fee_cents)
    @total_net = @total_revenue - @total_fees
  end

  # GET /charges/:id
  # Show individual transaction details
  def show
    @transaction = Current.organization.platform_transactions.find(params[:id])
  end

  private

  # Strong parameters for charge creation
  def charge_params
    params.require(:charge).permit(:amount_cents, :customer_email, :description, metadata: {})
  end

  # Ensure organization has active subscription
  def require_subscription
    unless Current.organization.on_trial_or_subscribed?
      redirect_to pricing_path, alert: "You need an active subscription to access payment features."
    end
  end

  # Ensure merchant has completed onboarding before creating charges
  def require_merchant_onboarded
    unless Current.organization.merchant_onboarding_complete?
      redirect_to new_connected_account_path,
                  alert: "Please complete Stripe Connect onboarding first."
    end
  end
end
