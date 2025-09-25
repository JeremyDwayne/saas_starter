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
- **User**: Main user model with `has_secure_password`, email validation
- **Session**: Tracks user sessions with IP and user agent
- **OmniAuthIdentity**: Links users to OAuth providers

### Controllers
- **ApplicationController**: Includes Authentication concern, requires authentication by default
- **SessionsController**: Handles login/logout
- **Sessions::OmniAuthsController**: OAuth callback handling
- **PasswordsController**: Password reset functionality
- **HomeController**: Landing page (allows unauthenticated access)

### Database Schema
- Uses SQLite with UUID extension for IDs
- Core tables: `users`, `sessions`, `omni_auth_identities`
- Payment tables: Pay gem integration for Stripe subscriptions
- Solid Cache/Queue/Cable tables for Rails services

### Migration Safety System
- **Unsafe migration detection** prevents dangerous operations on large tables
- **Automatic checks** for table size (>5GB) and row count (>5M rows)
- **SQLite optimized** with appropriate size estimation methods
- **Development bypass** using `FORCE_MIGRATION=true`
- **Smart handling** of `execute`, `change_column`, and `drop_table` operations
- **Configuration**: `lib/active_record/detect_unsafe_migrations.rb`

## Configuration Notes

- **Session storage**: Cookie-based with key `_interslice_session`
- **OAuth providers**: Configured in `config/initializers/omniauth_providers.rb`
- **Asset pipeline**: Uses Propshaft with Tailwind CSS
- **Deployment ready**: Includes Docker, Kamal, and Thruster configurations

## Development Patterns

- **Controllers**: Use `allow_unauthenticated_access` to skip authentication
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