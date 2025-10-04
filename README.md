# Rails SaaS Starter

> A production-ready Rails 8.1 SaaS starter kit with authentication, payments, referrals, and admin dashboard.

[![Rails](https://img.shields.io/badge/Rails-8.1%20beta-red.svg)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.5-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 🚀 Features

- **🔐 Authentication System**
  - Session-based authentication with secure password handling
  - OAuth integration (Google & GitHub)
  - Password reset flow with time-limited tokens
  - Multi-session management with device tracking

- **💳 Payment Processing**
  - Stripe integration via Pay gem
  - Subscription management with trial periods
  - Automated billing and invoice generation
  - PDF receipt generation
  - **Stripe Connect for marketplace payments**
    - Direct charges to connected accounts
    - Subscription-tiered platform fees
    - Custom fee overrides for enterprise customers
    - Real-time fee calculations

- **🎁 Referral System**
  - Automatic referral tracking with unique codes
  - Cookie-based conversion tracking
  - Automated credit rewards for successful referrals
  - Credit application to subscription invoices

- **👥 Role-Based Access Control (RBAC)**
  - Multi-role user system
  - Granular permission management
  - Resource-level access control

- **🎛️ Admin Dashboard**
  - Madmin-powered admin interface
  - User, session, and subscription management
  - Referral reward tracking
  - Platform fee configuration management
  - Transaction and merchant account oversight

- **🔧 Modern Rails Stack**
  - Rails 8.1 with SQLite database
  - Hotwire (Turbo + Stimulus)
  - Tailwind CSS for styling
  - Solid Cache/Queue/Cable for backing services

## 📋 Prerequisites

- Ruby 3.4.5
- Node.js (for asset compilation)
- SQLite 3
- Stripe account (for payments)
- Google/GitHub OAuth apps (for social login)

## 🛠️ Installation

### 1. Clone the repository

```bash
git clone <repository-url>
cd saas_starter
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Set up the database

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 4. Install Git hooks

```bash
./bin/setup-hooks
```

This sets up the pre-commit hook that automatically runs RuboCop on staged files.

### 5. Configure credentials

Edit your encrypted credentials file:

```bash
bin/rails credentials:edit
```

Add the following structure:

```yaml
auth:
  google:
    client_id: your_google_client_id
    secret: your_google_secret
  github:
    client_id: your_github_client_id
    secret: your_github_secret

stripe:
  public_key: your_stripe_public_key
  secret_key: your_stripe_secret_key
  signing_secret: your_stripe_webhook_signing_secret
```

### 6. Start the development server

```bash
bin/dev
```

This starts both the Rails server and watches for CSS changes.

Visit [http://localhost:3000](http://localhost:3000)

## 🧪 Testing

Run the full test suite:

```bash
bin/rails test
```

Run specific test file:

```bash
bin/rails test test/models/user_test.rb
```

Run system tests:

```bash
bin/rails test:system
```

## 📁 Project Structure

```
├── app/
│   ├── controllers/
│   │   ├── concerns/
│   │   │   └── authentication.rb      # Authentication logic
│   │   ├── sessions_controller.rb     # Login/logout
│   │   ├── passwords_controller.rb    # Password reset
│   │   ├── subscriptions_controller.rb # Payment flows
│   │   ├── settings_controller.rb     # User settings
│   │   ├── connected_accounts_controller.rb # Stripe Connect onboarding
│   │   └── platform_charges_controller.rb   # Marketplace payments
│   ├── models/
│   │   ├── current.rb                 # Request-scoped data
│   │   ├── user.rb                    # User model
│   │   ├── session.rb                 # Session tracking
│   │   ├── role.rb                    # RBAC roles
│   │   ├── platform_fee_configuration.rb # Tier-based fees
│   │   ├── custom_platform_fee.rb     # User-specific fees
│   │   └── platform_transaction.rb    # Payment transactions
│   ├── services/
│   │   ├── referral_reward_service.rb # Reward processing
│   │   ├── credit_application_service.rb # Credit application
│   │   ├── fee_calculation_service.rb # Platform fee calculations
│   │   └── platform_charge_service.rb # Stripe Connect charges
│   ├── jobs/
│   │   ├── referral_reward_webhook_job.rb
│   │   ├── credit_application_webhook_job.rb
│   │   └── connected_account_webhook_job.rb
│   └── views/
├── config/
│   ├── initializers/
│   │   └── omniauth_providers.rb      # OAuth configuration
│   └── routes/
│       └── madmin.rb                  # Admin routes
├── lib/
│   └── active_record/
│       └── detect_unsafe_migrations.rb # Migration safety
└── test/
```

## 🔑 Key Features Explained

### Authentication

The authentication system uses a session-based approach with the `Current` object pattern for request-scoped data:

```ruby
# Check if user is authenticated
if Current.user
  # User is logged in
end

# Require authentication in controllers
class MyController < ApplicationController
  # Authentication required by default
end

# Skip authentication for specific actions
class PublicController < ApplicationController
  allow_unauthenticated_access
end
```

### RBAC System

Manage user roles and permissions:

```ruby
# Assign roles
user.assign_role(:admin)
user.assign_role(:moderator)

# Check roles
user.has_role?(:admin) # => true
user.role_names        # => ["admin", "moderator"]

# Check permissions
user.has_permission?('manage_users')
user.has_permission_for?('posts', 'delete')

# Remove roles
user.remove_role(:moderator)
```

### Payment Processing

Subscription management with Stripe:

```ruby
# Check subscription status
user.subscribed?              # => true/false
user.on_trial?                # => true/false
user.on_trial_or_subscribed?  # => true/false

# Get subscription details
subscription = user.subscription
subscription.active?          # => true/false
subscription.on_trial?        # => true/false
```

### Referral System

Track and reward referrals:

```ruby
# Get user's referral code
user.referral_code            # => "ABC123"

# Check referral stats
user.successful_referrals_count
user.available_credit_balance
user.total_earned_credits

# Configuration
config = ReferralConfiguration.instance
config.reward_percentage      # Percentage of first payment as reward
config.max_credit_per_referral # Maximum credit per referral
config.credit_expiry_days     # Days until credits expire
```

### Stripe Connect (Marketplace Payments)

Enable users to accept payments directly from their customers with subscription-tiered platform fees:

```ruby
# Check if user can accept payments
user.merchant_onboarding_complete?  # => true/false
user.can_accept_payments?           # => true/false

# Get platform fee percentage
user.platform_fee_percentage        # => 5.0 (percentage)

# Calculate fees for a charge
fee_calculation = FeeCalculationService.calculate_for_user(user, 10000)
# => {
#   amount_cents: 10000,
#   fee_cents: 500,
#   fee_percentage: 5.0,
#   net_amount_cents: 9500,
#   fee_source: "tier"  # or "custom" or "default"
# }

# Create a charge on a connected account
result = PlatformChargeService.create_charge(
  merchant: user,
  amount_cents: 10000,
  customer_email: "customer@example.com",
  description: "Product purchase",
  metadata: { order_id: "123" }
)
```

**Platform Fee Tiers** (configurable in admin):
- Personal: 7% (default for users without subscription)
- Professional: 5%
- Enterprise: 3%
- Custom: Negotiated rates for specific users

**Features:**
- Direct charges - customers see merchant's business name
- Automatic fee calculation based on subscription tier
- Transaction history and reporting
- Stripe Express Dashboard access for merchants
- Webhook handling for account updates and refunds

### Migration Safety

The application includes automatic detection of unsafe migrations on large tables:

```bash
# Run migrations (with safety checks)
bin/rails db:migrate

# Bypass safety checks in development
FORCE_MIGRATION=true bin/rails db:migrate
```

## 🎨 Code Quality

### Linting

```bash
# Run RuboCop
rubocop

# Auto-fix issues
rubocop -A
```

### Security Audits

```bash
# Audit gems for vulnerabilities
bundle audit

# Static security analysis
brakeman
```

### Git Hooks

The pre-commit hook automatically:
- Runs `rubocop -A` on staged Ruby files
- Auto-corrects style issues
- Re-stages corrected files
- Prevents commits with unfixable issues

Bypass only in emergencies:
```bash
git commit --no-verify
```

## 🚢 Deployment

The application includes Docker, Kamal, and Thruster configurations for deployment.

### Using Kamal

```bash
# Setup Kamal
kamal setup

# Deploy
kamal deploy

# Check status
kamal app logs
```

### Environment Variables

Configure these in your production environment:

- `RAILS_MASTER_KEY` - Master key for credentials
- `DATABASE_URL` - Production database URL (if not using SQLite)
- Stripe webhook endpoint must be configured to point to `/pay/webhooks/stripe`

## 📊 Admin Dashboard

Access the admin dashboard at `/madmin` (requires admin role):

- Manage users and sessions
- View subscription details
- Track referral rewards
- Monitor OAuth identities
- Configure platform fee tiers
- Manage custom fee overrides
- View and analyze platform transactions

## 🔧 Development Commands

| Command | Description |
|---------|-------------|
| `bin/dev` | Start server with CSS watching |
| `bin/rails server` | Start Rails server only |
| `bin/rails console` | Open Rails console |
| `bin/rails db:migrate` | Run database migrations |
| `bin/rails db:reset` | Reset database |
| `bin/rails test` | Run all tests |
| `rubocop -A` | Auto-fix linting issues |
| `bundle audit` | Security audit |
| `brakeman` | Static security analysis |

## 🤝 Contributing

1. Ensure all tests pass: `bin/rails test`
2. Code passes RuboCop: `rubocop`
3. Write tests for new features
4. Follow the Rails Omakase style guide

## 📄 License

This project is available as open source under the terms of the [MIT License](LICENSE).

## 🙏 Acknowledgments

Built with:
- [Rails 8.1](https://rubyonrails.org/)
- [Pay](https://github.com/pay-rails/pay) - Stripe integration
- [Refer](https://github.com/andrewculver/refer) - Referral tracking
- [Madmin](https://github.com/excid3/madmin) - Admin dashboard
- [Tailwind CSS](https://tailwindcss.com/) - Styling
- [Hotwire](https://hotwired.dev/) - Modern JavaScript

---

**Need help?** Check out the [CLAUDE.md](CLAUDE.md) file for detailed project documentation.
