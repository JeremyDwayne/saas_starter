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
- **User**: Main user model with `has_secure_password`, email validation, Pay gem integration for payments
- **Session**: Tracks user sessions with IP and user agent
- **OmniAuthIdentity**: Links users to OAuth providers
- **Role**: RBAC roles with many-to-many relationship to permissions
- **Permission**: Granular permissions with resource and action fields
- **ReferralReward**: Credits earned from successful referrals
- **ReferralConfiguration**: System-wide referral reward settings

### Controllers
- **ApplicationController**: Includes Authentication concern, requires authentication by default, sets referral cookies
- **SessionsController**: Handles login/logout
- **Sessions::OmniAuthsController**: OAuth callback handling
- **PasswordsController**: Password reset functionality
- **SubscriptionsController**: Manages Stripe subscriptions and payment flows
- **SettingsController**: User profile, password changes, and account deletion
- **PagesController**: Public and authenticated pages (home, pricing, dashboard)

### Database Schema
- Uses SQLite with UUID extension for IDs
- Core tables: `users`, `sessions`, `omni_auth_identities`
- RBAC tables: `roles`, `permissions`, `role_permissions`, `user_roles`
- Payment tables: Pay gem integration for Stripe subscriptions (`pay_customers`, `pay_subscriptions`, `pay_charges`, etc.)
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

### Payment Processing
- **Pay gem**: Handles Stripe integration with `pay_customer` and `pay_merchant` on User model
- **Subscriptions**: Trial periods, active status checks, and automatic billing
- **Receipts**: PDF receipt generation via receipts gem
- **Webhooks**: Stripe webhooks handled at `/pay/webhooks/stripe`
- **User methods**: `user.subscribed?`, `user.subscription`, `user.on_trial?`, `user.on_trial_or_subscribed?`

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

- **Controllers**: Use `allow_unauthenticated_access` to skip authentication
- **Service objects**: Business logic in `app/services/` for complex operations
- **Background jobs**: Webhook processing in `app/jobs/` using Solid Queue
- **Views**: Tailwind CSS for styling, Turbo for interactions
- **Testing**: Minitest with fixtures, includes session test helpers
- **Security**: CSRF protection, secure password handling, content security policy

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
