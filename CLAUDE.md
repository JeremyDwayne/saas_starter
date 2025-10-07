# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.1 SaaS starter application with authentication, session management, and OAuth integration. The application uses:

- **Rails 8.1 (beta)** with SQLite database
- **Authentication system** with sessions, password reset, and OAuth (Google/GitHub)
- **Tailwind CSS** for styling with asset pipeline
- **Hotwire** (Turbo + Stimulus) for JavaScript interactions
- **Solid Cache/Queue/Cable** for Rails backing services

## Key Commands

### Development
```bash
# Start development server
bin/rails server

# Start development with CSS watching (recommended)
bin/dev

# Watch CSS changes only
bin/rails tailwindcss:watch

# Console
bin/rails console
```

### Database
```bash
# Run migrations
bin/rails db:migrate

# Reset database
bin/rails db:reset

# Create database
bin/rails db:create
```

### Testing
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run system tests
bin/rails test:system
```

### Code Quality
```bash
# Security audit
bundle audit

# Static security analysis
brakeman

# Linting (Omakase Ruby style)
rubocop

# Auto-fix linting issues
rubocop -A
```

### Migration Safety
```bash
# Run migrations with safety checks (production)
bin/rails db:migrate

# Force unsafe migrations (development only)
FORCE_MIGRATION=true bin/rails db:migrate
```

## Architecture

### Authentication System
- **Session-based authentication** using signed cookies
- **Current object pattern** (`app/models/current.rb`) for request-scoped data
- **Authentication concern** (`app/controllers/concerns/authentication.rb`) included in ApplicationController
- **OAuth integration** with Google and GitHub via OmniAuth
- **Password reset flow** with time-limited tokens

### Key Models
- **User**: Main user model with `has_secure_password`, email validation, belongs to multiple organizations
- **Organization**: Multi-tenant container for subscriptions, Stripe Connect, and business data. Has Pay gem integration (`pay_customer`, `pay_merchant`)
- **OrganizationMembership**: Join table linking users to organizations with role (admin/member)
- **Onboarding**: Tracks 4-step onboarding progress per organization (profile, org details, platform config, Stripe Connect)
- **Session**: Tracks user sessions with IP and user agent
- **OmniAuthIdentity**: Links users to OAuth providers
- **Role**: RBAC roles with many-to-many relationship to permissions
- **Permission**: Granular permissions with resource and action fields
- **ReferralReward**: Credits earned from successful referrals
- **ReferralConfiguration**: System-wide referral reward settings

### Controllers
- **ApplicationController**: Includes Authentication and OrganizationContext concerns, requires authentication by default, sets referral cookies
- **SessionsController**: Handles login/logout
- **Sessions::OmniAuthsController**: OAuth callback handling
- **PasswordsController**: Password reset functionality
- **OrganizationsController**: CRUD for organizations, organization switching via session
- **OrganizationMembersController**: Manage organization members
- **OrganizationInvitationsController**: Email-based organization invitations
- **OnboardingsController**: 4-step wizard for new organizations (profile → org details → platform config → Stripe Connect)
- **SubscriptionsController**: Manages organization-level Stripe subscriptions and payment flows
- **ConnectedAccountsController**: Handles Stripe Connect onboarding for organizations
- **SettingsController**: User-specific settings (profile, password, OAuth accounts, referrals, account deletion)
- **PagesController**: Public and authenticated pages (home, pricing, dashboard)

### Database Schema
- Uses SQLite with UUID extension for IDs
- Core tables: `users`, `sessions`, `omni_auth_identities`
- Organization tables: `organizations`, `organization_memberships`, `organization_invitations`, `onboardings`
- RBAC tables: `roles`, `permissions`, `role_permissions`, `user_roles`
- Payment tables: Pay gem integration for Stripe subscriptions (`pay_customers`, `pay_subscriptions`, `pay_charges`, etc.)
- Merchant tables: `merchant_customers`, `merchant_products`, `merchant_invoices`, `merchant_invoice_items`, `platform_transactions`
- Platform fee tables: `platform_fee_configurations`, `custom_platform_fees`
- Referral tables: `refer_referrals`, `refer_referral_codes`, `refer_visits` (from refer gem)
- Reward tables: `referral_rewards`, `referral_configurations`
- Solid Cache/Queue/Cable tables for Rails services

### Migration Safety System
- **Unsafe migration detection** prevents dangerous operations on large tables
- **Automatic checks** for table size (>5GB) and row count (>5M rows)
- **SQLite optimized** with appropriate size estimation methods
- **Development bypass** using `FORCE_MIGRATION=true`
- **Smart handling** of `execute`, `change_column`, and `drop_table` operations
- **Configuration**: `lib/active_record/detect_unsafe_migrations.rb`

### Role-Based Access Control (RBAC)
- **User roles**: Users can have multiple roles through `user_roles` join table
- **Permission system**: Granular permissions with resource and action attributes
- **Helper methods**: `user.has_role?(:admin)`, `user.has_permission?('manage_users')`, `user.has_permission_for?('posts', 'delete')`
- **Role management**: `user.assign_role(:admin)`, `user.remove_role(:admin)`, `user.role_names`

### Referral System
- **Refer gem integration**: Automatic referral tracking with codes, visits, and conversions
- **Referral codes**: Each user gets a unique referral code (`user.referral_code`)
- **Cookie tracking**: Referral codes stored in cookies via `set_referral_cookie` in ApplicationController
- **Conversion tracking**: Referrals marked as completed when referee signs up

### Referral Rewards System
- **Automatic credit awarding**: Credits automatically awarded when referred users complete trial and make first payment
- **Credit application**: Credits automatically applied to subscription invoices via Stripe webhook
- **Service objects**:
  - `ReferralRewardService`: Processes subscription payments and creates rewards
  - `CreditApplicationService`: Applies available credits to Stripe invoices
- **Webhook jobs**:
  - `ReferralRewardWebhookJob`: Triggered on `charge.succeeded` events
  - `CreditApplicationWebhookJob`: Triggered on `invoice.created` events
- **User methods**: `user.available_credit_balance`, `user.total_earned_credits`, `user.successful_referrals_count`
- **Configuration**: Managed via `ReferralConfiguration` model with reward percentage, max credits, and expiry settings

### Multi-Tenant Organization System
- **Organization context**: Stored in session, set via `OrganizationContext` concern
- **Organization switching**: Users can switch between organizations via `POST /organizations/:id/switch`
- **Current organization**: Accessed via `Current.organization` and `current_organization` helper
- **Membership**: Each user-organization link has a role (admin/member) in `organization_memberships`
- **Invitations**: Email-based invitations with token-based acceptance flow
- **Onboarding**: 4-step wizard automatically triggered after first subscription payment

### Payment Processing
- **Organization-level subscriptions**: Subscriptions managed at organization level via Pay gem
- **Pay gem**: Organizations have `pay_customer` for subscriptions and `pay_merchant` for Stripe Connect
- **Stripe Connect**: Organizations connect their own Stripe accounts to accept customer payments
- **Platform fees**: Configurable per-tier fees (PlatformFeeConfiguration) or custom per-organization fees
- **Merchant invoicing**: Organizations can create invoices and charge their customers
- **Receipts**: PDF receipt generation via receipts gem
- **Webhooks**: Stripe webhooks handled at `/pay/webhooks/stripe`
- **Organization methods**: `organization.subscribed?`, `organization.subscription`, `organization.on_trial?`, `organization.merchant_onboarding_complete?`

### Admin Interface
- **Madmin**: Admin dashboard at `/madmin` for managing users, sessions, subscriptions, and rewards
- **Resources**: Pre-configured for User, Session, Pay models, ReferralReward, and OmniAuthIdentity
- **Routes**: Defined in `config/routes/madmin.rb`

## Configuration Notes

- **Session storage**: Cookie-based with key `_interslice_session`
- **OAuth providers**: Configured in `config/initializers/omniauth_providers.rb`
- **Asset pipeline**: Uses Propshaft with Tailwind CSS
- **Deployment ready**: Includes Docker, Kamal, and Thruster configurations
- **Stripe**: Webhooks configured in Procfile.dev for local development

## Development Patterns

- **Controllers**: Use `allow_unauthenticated_access` to skip authentication, `require_organization_context` to ensure organization is set
- **Service objects**: Business logic in `app/services/` for complex operations (e.g., `ReferralRewardService`, `CreditApplicationService`)
- **Background jobs**: Webhook processing in `app/jobs/` using Solid Queue
- **Views**: Tailwind CSS for styling, Turbo for interactions, Lucide icons via `lucide-rails` gem
- **Testing**: Minitest with fixtures, includes session test helpers
- **Security**: CSRF protection, secure password handling, content security policy
- **Caching**: Multi-level caching with Rails.cache (Solid Cache in production, memory_store in development)
  - Configuration models cached for 1 day
  - User roles/permissions cached for 1 hour
  - Organization data cached for 5 minutes to 1 hour
  - Fragment caching for view partials
  - Automatic cache invalidation via `after_commit` callbacks

## Git Hooks

### Setup Required
After cloning this repository, developers must run:
```bash
./bin/setup-hooks
```

### Pre-commit Hook
- **Automatic RuboCop**: Runs `rubocop -A` on staged Ruby files before each commit
- **Auto-correction**: Fixes formatting issues automatically and re-stages files
- **Quality gate**: Prevents commits if unfixable style issues exist
- **Configuration**: Uses Rails Omakase style guide
- **Bypass**: Use `git commit --no-verify` only for emergencies

The pre-commit hook ensures consistent code style across all commits without manual intervention.
- all tests must pass before committing changes `bin/rails test`

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
