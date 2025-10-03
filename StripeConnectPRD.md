# Stripe Connect Implementation - Product Requirements Document

## Overview
Add Stripe Connect to enable businesses to charge their customers through your platform using Direct Charges. Application fees will be based on subscription tiers with support for custom negotiated rates.

## Architecture

**Stripe Connect Model**: Direct Charges
- Customers are charged directly on the connected account (business appears on statement)
- Platform collects application fees automatically
- Businesses receive net amount (charge - Stripe fees - platform fee)

## Implementation Components

### 1. Database Schema (3 migrations)

**Migration 1: Platform Fee Configuration**
```ruby
class CreatePlatformFeeConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_fee_configurations, id: :string, default: -> { "uuid()" } do |t|
      t.string :subscription_tier, null: false # personal, professional, enterprise
      t.decimal :fee_percentage, precision: 5, scale: 2, null: false
      t.integer :minimum_fee_cents # Optional minimum fee
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :platform_fee_configurations, :subscription_tier, unique: true
    add_index :platform_fee_configurations, :active
  end
end
```

**Migration 2: Custom Fee Overrides**
```ruby
class CreateCustomPlatformFees < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_platform_fees, id: :string, default: -> { "uuid()" } do |t|
      t.string :user_id, null: false
      t.decimal :fee_percentage, precision: 5, scale: 2, null: false
      t.integer :minimum_fee_cents
      t.string :notes # Negotiation details
      t.date :expires_at # Optional expiry
      t.timestamps
    end

    add_foreign_key :custom_platform_fees, :users
    add_index :custom_platform_fees, :user_id, unique: true
    add_index :custom_platform_fees, :expires_at
  end
end
```

**Migration 3: Platform Transactions**
```ruby
class CreatePlatformTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_transactions, id: :string, default: -> { "uuid()" } do |t|
      t.string :merchant_id, null: false
      t.string :stripe_charge_id, null: false
      t.integer :charge_amount_cents, null: false
      t.integer :application_fee_cents, null: false
      t.decimal :fee_percentage_applied, precision: 5, scale: 2
      t.string :customer_email
      t.string :description
      t.json :metadata
      t.string :status, default: 'succeeded' # succeeded, refunded, partially_refunded
      t.timestamps
    end

    add_foreign_key :platform_transactions, :users, column: :merchant_id
    add_index :platform_transactions, :merchant_id
    add_index :platform_transactions, :stripe_charge_id, unique: true
    add_index :platform_transactions, :status
    add_index :platform_transactions, :created_at
  end
end
```

### 2. Models (4 new + 1 update)

**PlatformFeeConfiguration Model**
```ruby
# app/models/platform_fee_configuration.rb
class PlatformFeeConfiguration < ApplicationRecord
  validates :subscription_tier, presence: true, uniqueness: true
  validates :fee_percentage, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :minimum_fee_cents, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }

  VALID_TIERS = %w[personal professional enterprise none].freeze
  validates :subscription_tier, inclusion: { in: VALID_TIERS }

  def self.fee_for_tier(tier)
    active.find_by(subscription_tier: tier&.to_s&.downcase)
  end

  def calculate_application_fee(charge_amount_cents)
    fee = (charge_amount_cents * (fee_percentage / 100.0)).round

    if minimum_fee_cents.present?
      [fee, minimum_fee_cents].max
    else
      fee
    end
  end

  def fee_percentage_display
    "#{fee_percentage}%"
  end
end
```

**CustomPlatformFee Model**
```ruby
# app/models/custom_platform_fee.rb
class CustomPlatformFee < ApplicationRecord
  belongs_to :user

  validates :fee_percentage, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :minimum_fee_cents, numericality: { greater_than: 0 }, allow_nil: true
  validates :user_id, uniqueness: true

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Date.current) }

  def active?
    expires_at.nil? || expires_at > Date.current
  end

  def calculate_application_fee(charge_amount_cents)
    fee = (charge_amount_cents * (fee_percentage / 100.0)).round

    if minimum_fee_cents.present?
      [fee, minimum_fee_cents].max
    else
      fee
    end
  end

  def fee_percentage_display
    "#{fee_percentage}%"
  end
end
```

**PlatformTransaction Model**
```ruby
# app/models/platform_transaction.rb
class PlatformTransaction < ApplicationRecord
  belongs_to :merchant, class_name: 'User', foreign_key: 'merchant_id'

  validates :stripe_charge_id, presence: true, uniqueness: true
  validates :charge_amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :application_fee_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fee_percentage_applied, presence: true
  validates :status, presence: true, inclusion: { in: %w[succeeded refunded partially_refunded] }

  scope :succeeded, -> { where(status: 'succeeded') }
  scope :refunded, -> { where(status: 'refunded') }
  scope :for_merchant, ->(merchant_id) { where(merchant_id: merchant_id) }
  scope :recent, -> { order(created_at: :desc) }

  def charge_amount_dollars
    charge_amount_cents / 100.0
  end

  def application_fee_dollars
    application_fee_cents / 100.0
  end

  def net_amount_cents
    charge_amount_cents - application_fee_cents
  end

  def net_amount_dollars
    net_amount_cents / 100.0
  end

  def refunded?
    status == 'refunded'
  end

  def partially_refunded?
    status == 'partially_refunded'
  end
end
```

**User Model Updates**
```ruby
# Add to app/models/user.rb

# Existing pay_merchant is already there from line 12

# Add these methods:

def platform_fee_percentage
  # Check for custom fee first
  custom_fee = custom_platform_fee
  return custom_fee.fee_percentage if custom_fee&.active?

  # Fall back to tier-based fee
  tier = current_subscription_tier
  config = PlatformFeeConfiguration.fee_for_tier(tier)
  config&.fee_percentage || default_platform_fee_percentage
end

def calculate_platform_fee(amount_cents)
  custom_fee = custom_platform_fee
  if custom_fee&.active?
    return custom_fee.calculate_application_fee(amount_cents)
  end

  tier = current_subscription_tier
  config = PlatformFeeConfiguration.fee_for_tier(tier)

  if config
    config.calculate_application_fee(amount_cents)
  else
    # Default to highest fee if no subscription
    (amount_cents * (default_platform_fee_percentage / 100.0)).round
  end
end

def current_subscription_tier
  return 'none' unless subscription

  # Extract tier from subscription metadata or name
  subscription.name&.downcase || 'none'
end

def merchant_onboarding_complete?
  return false unless merchant_processor
  merchant_processor.onboarding_complete?
rescue
  false
end

def can_accept_payments?
  merchant_onboarding_complete? && on_trial_or_subscribed?
end

# Associations
has_one :custom_platform_fee, dependent: :destroy
has_many :platform_transactions, foreign_key: 'merchant_id', dependent: :destroy

private

def default_platform_fee_percentage
  7.0 # Highest fee for users without subscription
end
```

### 3. Services (2 new)

**FeeCalculationService**
```ruby
# app/services/fee_calculation_service.rb
class FeeCalculationService
  def self.calculate_for_user(user, amount_cents)
    new(user, amount_cents).calculate
  end

  def initialize(user, amount_cents)
    @user = user
    @amount_cents = amount_cents
  end

  def calculate
    {
      amount_cents: @amount_cents,
      fee_cents: fee_amount,
      fee_percentage: fee_percentage,
      net_amount_cents: @amount_cents - fee_amount,
      fee_source: fee_source
    }
  end

  private

  def fee_amount
    @user.calculate_platform_fee(@amount_cents)
  end

  def fee_percentage
    @user.platform_fee_percentage
  end

  def fee_source
    if @user.custom_platform_fee&.active?
      'custom'
    elsif @user.subscription
      'tier'
    else
      'default'
    end
  end
end
```

**PlatformChargeService**
```ruby
# app/services/platform_charge_service.rb
class PlatformChargeService
  class ChargeError < StandardError; end
  class OnboardingIncompleteError < StandardError; end
  class SubscriptionRequiredError < StandardError; end

  def self.create_charge(merchant:, amount_cents:, customer_email:, description: nil, metadata: {})
    new(merchant, amount_cents, customer_email, description, metadata).create_charge
  end

  def initialize(merchant, amount_cents, customer_email, description, metadata)
    @merchant = merchant
    @amount_cents = amount_cents
    @customer_email = customer_email
    @description = description || "Payment processed via platform"
    @metadata = metadata || {}
  end

  def create_charge
    validate_merchant!

    fee_calculation = calculate_fee

    begin
      # Create charge on connected account with application fee
      charge = Stripe::Charge.create({
        amount: @amount_cents,
        currency: 'usd',
        description: @description,
        receipt_email: @customer_email,
        metadata: @metadata.merge({
          merchant_id: @merchant.id,
          merchant_email: @merchant.email,
          platform_charge: true
        }),
        application_fee_amount: fee_calculation[:fee_cents]
      }, {
        stripe_account: @merchant.merchant_processor.processor_id
      })

      # Record transaction
      transaction = record_transaction(charge, fee_calculation)

      {
        success: true,
        charge: charge,
        transaction: transaction,
        fee_calculation: fee_calculation
      }
    rescue Stripe::StripeError => e
      Rails.logger.error "Platform charge failed: #{e.message}"
      raise ChargeError, e.message
    end
  end

  private

  def validate_merchant!
    unless @merchant.merchant_onboarding_complete?
      raise OnboardingIncompleteError, "Merchant must complete Stripe Connect onboarding"
    end

    unless @merchant.on_trial_or_subscribed?
      raise SubscriptionRequiredError, "Merchant must have an active subscription"
    end
  end

  def calculate_fee
    FeeCalculationService.calculate_for_user(@merchant, @amount_cents)
  end

  def record_transaction(charge, fee_calculation)
    PlatformTransaction.create!(
      merchant: @merchant,
      stripe_charge_id: charge.id,
      charge_amount_cents: @amount_cents,
      application_fee_cents: fee_calculation[:fee_cents],
      fee_percentage_applied: fee_calculation[:fee_percentage],
      customer_email: @customer_email,
      description: @description,
      metadata: @metadata,
      status: 'succeeded'
    )
  end
end
```

### 4. Controllers (3 new)

**ConnectedAccountsController**
```ruby
# app/controllers/connected_accounts_controller.rb
class ConnectedAccountsController < ApplicationController
  before_action :require_subscription, only: [:create]

  def new
    # Show onboarding information page
    @fee_percentage = Current.user.platform_fee_percentage
  end

  def create
    # Create Stripe Connect account
    begin
      Current.user.set_merchant_processor(:stripe)
      account = Current.user.merchant_processor.create_account

      # Generate account link for onboarding
      account_link = Current.user.merchant_processor.account_link(
        refresh_url: refresh_connected_account_url,
        return_url: return_connected_account_url
      )

      redirect_to account_link, allow_other_host: true, status: :see_other
    rescue => e
      Rails.logger.error "Failed to create connected account: #{e.message}"
      redirect_to new_connected_account_path, alert: "Failed to start onboarding. Please try again."
    end
  end

  def return
    # Handle successful onboarding return
    if Current.user.merchant_onboarding_complete?
      flash[:notice] = "Your account is connected! You can now accept payments."
    else
      flash[:warning] = "Onboarding incomplete. Please complete all required steps."
    end
    redirect_to settings_path
  end

  def refresh
    # Regenerate onboarding link if user needs to complete setup
    begin
      account_link = Current.user.merchant_processor.account_link(
        refresh_url: refresh_connected_account_url,
        return_url: return_connected_account_url
      )
      redirect_to account_link, allow_other_host: true, status: :see_other
    rescue => e
      Rails.logger.error "Failed to refresh account link: #{e.message}"
      redirect_to settings_path, alert: "Failed to refresh onboarding. Please try again."
    end
  end

  def dashboard
    # Redirect to Stripe Express Dashboard
    begin
      login_link = Current.user.merchant_processor.login_link
      redirect_to login_link, allow_other_host: true, status: :see_other
    rescue => e
      Rails.logger.error "Failed to generate dashboard link: #{e.message}"
      redirect_to settings_path, alert: "Failed to access dashboard. Please try again."
    end
  end

  private

  def require_subscription
    unless Current.user.on_trial_or_subscribed?
      redirect_to pricing_path, alert: "You need an active subscription to connect your account."
    end
  end
end
```

**PlatformChargesController**
```ruby
# app/controllers/platform_charges_controller.rb
class PlatformChargesController < ApplicationController
  before_action :require_merchant_onboarded, except: [:index, :show]

  def new
    @fee_calculation = FeeCalculationService.calculate_for_user(
      Current.user,
      params[:amount_cents]&.to_i || 1000
    )
  end

  def create
    result = PlatformChargeService.create_charge(
      merchant: Current.user,
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

  def index
    @transactions = Current.user.platform_transactions.recent.page(params[:page])

    # Summary stats
    @total_revenue = Current.user.platform_transactions.succeeded.sum(:charge_amount_cents)
    @total_fees = Current.user.platform_transactions.succeeded.sum(:application_fee_cents)
    @total_net = @total_revenue - @total_fees
  end

  def show
    @transaction = Current.user.platform_transactions.find(params[:id])
  end

  private

  def charge_params
    params.require(:charge).permit(:amount_cents, :customer_email, :description, metadata: {})
  end

  def require_merchant_onboarded
    unless Current.user.merchant_onboarding_complete?
      redirect_to new_connected_account_path,
                  alert: "Please complete Stripe Connect onboarding first."
    end
  end
end
```

**Admin Controllers (Madmin)**
```ruby
# app/madmin/resources/platform_fee_configuration_resource.rb
class PlatformFeeConfigurationResource < Madmin::Resource
  attribute :id, form: false
  attribute :subscription_tier
  attribute :fee_percentage
  attribute :minimum_fee_cents
  attribute :active
  attribute :created_at, form: false
  attribute :updated_at, form: false
end

# app/madmin/resources/custom_platform_fee_resource.rb
class CustomPlatformFeeResource < Madmin::Resource
  attribute :id, form: false
  attribute :user
  attribute :fee_percentage
  attribute :minimum_fee_cents
  attribute :notes
  attribute :expires_at
  attribute :created_at, form: false
  attribute :updated_at, form: false
end

# app/madmin/resources/platform_transaction_resource.rb
class PlatformTransactionResource < Madmin::Resource
  attribute :id, form: false
  attribute :merchant
  attribute :stripe_charge_id
  attribute :charge_amount_cents
  attribute :application_fee_cents
  attribute :fee_percentage_applied
  attribute :customer_email
  attribute :description
  attribute :status
  attribute :created_at, form: false
  attribute :updated_at, form: false
end
```

### 5. Views & UI

**Connected Account Onboarding**
```erb
<!-- app/views/connected_accounts/new.html.erb -->
<div class="max-w-3xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-4">Connect Your Stripe Account</h1>

  <div class="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
    <h2 class="text-xl font-semibold mb-2">Your Platform Fee</h2>
    <p class="text-3xl font-bold text-blue-600"><%= @fee_percentage %>%</p>
    <p class="text-sm text-gray-600 mt-2">
      This fee will be automatically deducted from each transaction
    </p>
  </div>

  <div class="bg-white border rounded-lg p-6 mb-6">
    <h3 class="font-semibold mb-4">What you'll need:</h3>
    <ul class="space-y-2">
      <li>✓ Business information</li>
      <li>✓ Bank account details</li>
      <li>✓ Tax identification number</li>
      <li>✓ Personal identification</li>
    </ul>
  </div>

  <%= button_to "Connect Stripe Account",
      connected_account_path,
      method: :post,
      class: "w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg" %>
</div>
```

**Payment Form**
```erb
<!-- app/views/platform_charges/new.html.erb -->
<div class="max-w-2xl mx-auto p-6">
  <h1 class="text-3xl font-bold mb-6">Create Charge</h1>

  <%= form_with model: :charge, url: charges_path, local: true do |f| %>
    <div class="mb-4">
      <%= f.label :amount_cents, "Amount (cents)", class: "block font-medium mb-2" %>
      <%= f.number_field :amount_cents,
          value: 1000,
          class: "w-full border rounded-lg px-4 py-2",
          data: { action: "input->fee-calculator#calculate" } %>
    </div>

    <div class="mb-4">
      <%= f.label :customer_email, "Customer Email", class: "block font-medium mb-2" %>
      <%= f.email_field :customer_email,
          class: "w-full border rounded-lg px-4 py-2",
          required: true %>
    </div>

    <div class="mb-4">
      <%= f.label :description, "Description", class: "block font-medium mb-2" %>
      <%= f.text_area :description,
          class: "w-full border rounded-lg px-4 py-2",
          rows: 3 %>
    </div>

    <div class="bg-gray-50 border rounded-lg p-4 mb-6">
      <h3 class="font-semibold mb-2">Fee Breakdown</h3>
      <div class="space-y-1 text-sm">
        <div class="flex justify-between">
          <span>Charge Amount:</span>
          <span class="font-mono">$<%= @fee_calculation[:amount_cents] / 100.0 %></span>
        </div>
        <div class="flex justify-between text-red-600">
          <span>Platform Fee (<%= @fee_calculation[:fee_percentage] %>%):</span>
          <span class="font-mono">-$<%= @fee_calculation[:fee_cents] / 100.0 %></span>
        </div>
        <div class="flex justify-between font-semibold border-t pt-1">
          <span>You Receive:</span>
          <span class="font-mono">$<%= @fee_calculation[:net_amount_cents] / 100.0 %></span>
        </div>
      </div>
    </div>

    <%= f.submit "Create Charge",
        class: "w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg" %>
  <% end %>
</div>
```

**Transaction History**
```erb
<!-- app/views/platform_charges/index.html.erb -->
<div class="max-w-6xl mx-auto p-6">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Transactions</h1>
    <%= link_to "New Charge", new_charge_path,
        class: "bg-blue-600 hover:bg-blue-700 text-white font-semibold py-2 px-4 rounded-lg" %>
  </div>

  <!-- Summary Cards -->
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
    <div class="bg-white border rounded-lg p-6">
      <p class="text-sm text-gray-600 mb-1">Total Revenue</p>
      <p class="text-3xl font-bold">$<%= @total_revenue / 100.0 %></p>
    </div>
    <div class="bg-white border rounded-lg p-6">
      <p class="text-sm text-gray-600 mb-1">Platform Fees</p>
      <p class="text-3xl font-bold text-red-600">$<%= @total_fees / 100.0 %></p>
    </div>
    <div class="bg-white border rounded-lg p-6">
      <p class="text-sm text-gray-600 mb-1">Net Amount</p>
      <p class="text-3xl font-bold text-green-600">$<%= @total_net / 100.0 %></p>
    </div>
  </div>

  <!-- Transactions Table -->
  <div class="bg-white border rounded-lg overflow-hidden">
    <table class="w-full">
      <thead class="bg-gray-50 border-b">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Customer</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Fee</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Net</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
        </tr>
      </thead>
      <tbody class="divide-y">
        <% @transactions.each do |transaction| %>
          <tr>
            <td class="px-6 py-4 text-sm"><%= transaction.created_at.strftime('%Y-%m-%d %H:%M') %></td>
            <td class="px-6 py-4 text-sm"><%= transaction.customer_email %></td>
            <td class="px-6 py-4 text-sm font-mono">$<%= transaction.charge_amount_dollars %></td>
            <td class="px-6 py-4 text-sm font-mono text-red-600">$<%= transaction.application_fee_dollars %></td>
            <td class="px-6 py-4 text-sm font-mono text-green-600">$<%= transaction.net_amount_dollars %></td>
            <td class="px-6 py-4 text-sm">
              <span class="px-2 py-1 text-xs rounded-full <%= transaction.succeeded? ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' %>">
                <%= transaction.status %>
              </span>
            </td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

**Settings Enhancement**
```erb
<!-- Add to app/views/settings/show.html.erb -->
<div class="bg-white border rounded-lg p-6 mb-6">
  <h2 class="text-xl font-semibold mb-4">Connected Account</h2>

  <% if Current.user.merchant_onboarding_complete? %>
    <div class="flex items-center justify-between">
      <div>
        <p class="text-green-600 font-medium">✓ Account Connected</p>
        <p class="text-sm text-gray-600">Platform fee: <%= Current.user.platform_fee_percentage %>%</p>
      </div>
      <div class="space-x-2">
        <%= link_to "View Transactions", charges_path,
            class: "bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg" %>
        <%= button_to "Stripe Dashboard", dashboard_connected_account_path,
            method: :get,
            class: "bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-lg" %>
      </div>
    </div>
  <% else %>
    <p class="text-gray-600 mb-4">Connect your Stripe account to accept payments</p>
    <%= link_to "Connect Stripe", new_connected_account_path,
        class: "bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg inline-block" %>
  <% end %>
</div>
```

### 6. Background Jobs

**ConnectedAccountWebhookJob**
```ruby
# app/jobs/connected_account_webhook_job.rb
class ConnectedAccountWebhookJob < ApplicationJob
  queue_as :default

  def perform(event)
    case event.type
    when 'account.updated'
      handle_account_updated(event)
    when 'charge.succeeded'
      handle_charge_succeeded(event)
    when 'charge.refunded'
      handle_charge_refunded(event)
    end
  end

  private

  def handle_account_updated(event)
    account_id = event.data['object']['id']
    merchant = Pay::Merchant.find_by(processor: 'stripe', processor_id: account_id)

    return unless merchant

    # Pay gem automatically updates onboarding_complete status
    Rails.logger.info "Updated account status for merchant: #{merchant.owner_id}"
  end

  def handle_charge_succeeded(event)
    charge_data = event.data['object']

    # Only handle platform charges (those with application fees)
    return unless charge_data['application_fee']

    # Transaction should already be recorded by PlatformChargeService
    # This webhook confirms the charge succeeded on Stripe's end
    transaction = PlatformTransaction.find_by(stripe_charge_id: charge_data['id'])

    if transaction
      Rails.logger.info "Confirmed charge success: #{transaction.id}"
    else
      Rails.logger.warn "Received charge.succeeded for unknown transaction: #{charge_data['id']}"
    end
  end

  def handle_charge_refunded(event)
    charge_data = event.data['object']
    transaction = PlatformTransaction.find_by(stripe_charge_id: charge_data['id'])

    return unless transaction

    if charge_data['refunded']
      transaction.update!(status: 'refunded')
      Rails.logger.info "Marked transaction as refunded: #{transaction.id}"
    elsif charge_data['amount_refunded'] > 0
      transaction.update!(status: 'partially_refunded')
      Rails.logger.info "Marked transaction as partially refunded: #{transaction.id}"
    end
  end
end
```

### 7. Configuration

**Webhook Subscriptions**
```ruby
# Add to config/initializers/pay_webhooks.rb

# Listen for Stripe Connect account updates
Pay::Webhooks.delegator.subscribe "stripe.account.updated" do |event|
  ConnectedAccountWebhookJob.perform_later(event)
end

# Listen for charges on connected accounts
Pay::Webhooks.delegator.subscribe "stripe.charge.succeeded" do |event|
  # Only process if it's a platform charge (has application fee)
  if event.data["object"]["application_fee"].present?
    ConnectedAccountWebhookJob.perform_later(event)
  end
end

# Listen for refunds
Pay::Webhooks.delegator.subscribe "stripe.charge.refunded" do |event|
  if event.data["object"]["application_fee"].present?
    ConnectedAccountWebhookJob.perform_later(event)
  end
end
```

**Stripe Webhooks Setup**
- Existing Pay gem webhook endpoint: `/pay/webhooks/stripe`
- Required webhook events (configure in Stripe Dashboard):
  - `account.updated`
  - `charge.succeeded`
  - `charge.refunded`

### 8. Routes

```ruby
# Add to config/routes.rb

# Connected account onboarding
resource :connected_account, only: [:new, :create] do
  collection do
    get :return
    get :refresh
    get :dashboard
  end
end

# Platform charges (for businesses)
resources :charges, controller: 'platform_charges', only: [:new, :create, :index, :show]

# Admin routes already handled by Madmin
# Add these resources to config/routes/madmin.rb:
# namespace :madmin do
#   resources :platform_fee_configurations
#   resources :custom_platform_fees
#   resources :platform_transactions
# end
```

### 9. Example Fee Structure (Seed Data)

```ruby
# db/seeds.rb or separate seed file

# Create default platform fee configurations
PlatformFeeConfiguration.find_or_create_by(subscription_tier: 'personal') do |config|
  config.fee_percentage = 5.0
  config.active = true
end

PlatformFeeConfiguration.find_or_create_by(subscription_tier: 'professional') do |config|
  config.fee_percentage = 3.0
  config.active = true
end

PlatformFeeConfiguration.find_or_create_by(subscription_tier: 'enterprise') do |config|
  config.fee_percentage = 2.0
  config.active = true
end

PlatformFeeConfiguration.find_or_create_by(subscription_tier: 'none') do |config|
  config.fee_percentage = 7.0
  config.active = true
end
```

### 10. User Experience Flow

**For Businesses (Merchants)**:
1. Subscribe to platform (Personal/Pro/Enterprise)
2. Navigate to Settings → Connect Stripe Account
3. Complete Stripe Connect onboarding
4. Start accepting payments with automated fee deduction
5. View transactions and access Stripe Dashboard

**For Platform Administrators**:
1. Set default fee percentages per tier in Madmin
2. Create custom fee overrides for special customers
3. Monitor platform revenue from fees
4. Generate financial reports

## Testing Requirements

### Unit Tests
- [ ] PlatformFeeConfiguration model validations
- [ ] CustomPlatformFee model validations
- [ ] PlatformTransaction model validations
- [ ] User model platform fee methods
- [ ] FeeCalculationService calculations
- [ ] PlatformChargeService charge creation

### Integration Tests
- [ ] Connected account onboarding flow
- [ ] Charge creation with application fees
- [ ] Webhook processing
- [ ] Fee calculation for different tiers
- [ ] Custom fee override logic
- [ ] Refund handling

### System Tests
- [ ] Complete merchant onboarding flow
- [ ] Create charge through UI
- [ ] View transaction history
- [ ] Admin fee configuration management

## Security Considerations

1. **Charge Validation**
   - Validate all amounts are positive integers
   - Verify merchant has completed onboarding
   - Ensure merchant has active subscription

2. **Data Sanitization**
   - Sanitize customer email and description
   - Validate metadata structure
   - Prevent SQL injection in queries

3. **Authorization**
   - Merchants can only view their own transactions
   - Only admins can modify fee configurations
   - Validate Stripe webhook signatures (handled by Pay gem)

4. **Audit Trail**
   - All transactions logged in PlatformTransaction
   - Track fee percentage applied at transaction time
   - Record metadata for debugging

5. **API Security**
   - Use Stripe's API securely via Pay gem
   - Store Stripe account IDs, never API keys
   - Validate webhook events

## Migration Rollout Plan

### Phase 1: Foundation (Week 1)
- [ ] Create migrations
- [ ] Create models
- [ ] Write tests for models
- [ ] Create seed data for fee configurations

### Phase 2: Services & Jobs (Week 1-2)
- [ ] Implement FeeCalculationService
- [ ] Implement PlatformChargeService
- [ ] Create ConnectedAccountWebhookJob
- [ ] Write tests for services

### Phase 3: Controllers & Views (Week 2)
- [ ] Build ConnectedAccountsController
- [ ] Build PlatformChargesController
- [ ] Create onboarding views
- [ ] Create charge views
- [ ] Update settings page

### Phase 4: Admin Interface (Week 2-3)
- [ ] Create Madmin resources
- [ ] Add admin routes
- [ ] Test admin functionality

### Phase 5: Testing & Polish (Week 3)
- [ ] Integration testing
- [ ] System testing
- [ ] Security review
- [ ] Documentation updates

### Phase 6: Deployment (Week 3-4)
- [ ] Deploy to staging
- [ ] Test with Stripe test mode
- [ ] Configure production webhooks
- [ ] Deploy to production
- [ ] Monitor first transactions

## Success Metrics

- Merchants successfully onboarded
- Charges processed with correct fees
- Zero fee calculation errors
- Webhook reliability > 99.9%
- Transaction reconciliation accuracy 100%

## Future Enhancements

- Support for partial refunds with fee adjustments
- Scheduled fee changes (tier downgrades)
- Volume-based fee discounts
- Multi-currency support
- Automated invoicing for application fees
- Analytics dashboard for platform revenue
- Merchant payout scheduling
- Dispute handling
