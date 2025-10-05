# Multi-Tenancy Implementation PRD

## Overview
Transform the single-tenant SaaS application into a multi-tenant B2B/B2B2C platform with organization-based architecture and context switching (similar to Stripe's organization switcher).

## Current State
- Users directly own all business data (invoices, customers, products)
- Subscriptions and Stripe Connect accounts belong to individual users
- No concept of teams, shared access, or multiple contexts
- Users cannot belong to multiple organizations

## Target State
- Organizations (tenants) own all business data
- Users can belong to multiple organizations with different roles
- Context switching between organizations via UI selector
- Team members can collaborate within organizations
- End users (customers) can purchase from multiple organizations using same login
- Subscriptions and Stripe Connect accounts belong to organizations

## Phase 1: Core Multi-Tenancy Infrastructure

### Task 1.1: Create Organization Model
- Create `organizations` table with UUID primary key
- Fields: name (required), slug (unique), settings (json), owner_id (user), created_at, updated_at
- Add indexes on slug, owner_id
- Create Organization model with validations
- Add associations: has_many :memberships, has_many :users through :memberships
- Generate slug from name on create
- Write model tests

### Task 1.2: Create Organization Membership Model
- Create `organization_memberships` table with UUID primary key
- Fields: organization_id, user_id, role (enum: owner, admin, member, billing_admin), created_at, updated_at
- Add unique index on [organization_id, user_id]
- Add indexes on organization_id, user_id, role
- Create OrganizationMembership model with validations
- Add role enum and role checking methods (owner?, admin?, can_manage_billing?)
- Add associations to Organization and User
- Write model tests

### Task 1.3: Create Invitation Model
- Create `invitations` table with UUID primary key
- Fields: organization_id, email, role, token (unique), inviter_id (user), accepted_at, expires_at, created_at, updated_at
- Add indexes on token (unique), organization_id, email
- Create Invitation model with validations
- Add token generation on create (SecureRandom.urlsafe_base64)
- Add expiration logic (default 7 days)
- Add accept/decline methods
- Write model tests

### Task 1.4: Update User Model for Organizations
- Add has_many :organization_memberships to User model
- Add has_many :organizations, through: :memberships
- Add has_many :owned_organizations, class_name: 'Organization', foreign_key: 'owner_id'
- Add helper methods: member_of?(org), admin_of?(org), owner_of?(org)
- Add method to get user's role in organization
- Update user tests

## Phase 2: Data Ownership Migration

### Task 2.1: Add organization_id to MerchantCustomer
- Create migration to add organization_id column (string, uuid)
- Add index on organization_id
- Add index on [organization_id, email]
- Update model: change belongs_to :user to belongs_to :organization
- Keep user_id temporarily for migration
- Update model tests and fixtures

### Task 2.2: Add organization_id to MerchantProduct
- Create migration to add organization_id column (string, uuid)
- Add index on organization_id
- Add index on [organization_id, active]
- Update model: change belongs_to :user to belongs_to :organization
- Keep user_id temporarily for migration
- Update model tests and fixtures

### Task 2.3: Add organization_id to MerchantInvoice
- Create migration to add organization_id column (string, uuid)
- Add index on organization_id
- Add index on [organization_id, invoice_number] (unique)
- Update model: change belongs_to :user to belongs_to :organization
- Keep user_id temporarily for migration
- Update model tests and fixtures

### Task 2.4: Add organization_id to PlatformTransaction
- Create migration to add organization_id column (string, uuid)
- Add index on organization_id
- Update model: change merchant_id to organization_id
- Update foreign key references
- Update model tests

### Task 2.5: Add organization_id to CustomPlatformFee
- Create migration to add organization_id column (string, uuid)
- Add unique index on organization_id
- Update model: change belongs_to :user to belongs_to :organization
- Update model tests and fixtures

### Task 2.6: Migrate Pay Customers to Organization Ownership
- Update Pay::Customer polymorphic owner to support Organization
- Create migration to change owner_type from 'User' to 'Organization' for subscription customers
- Migrate existing subscription data to organization ownership
- Update subscription checking logic in Organization model
- Test subscription flows with organization ownership

### Task 2.7: Migrate Pay Merchants to Organization Ownership
- Update Pay::Merchant polymorphic owner to support Organization
- Create migration to change owner_type from 'User' to 'Organization' for merchant accounts
- Migrate existing Connect account data to organization ownership
- Update Connect onboarding logic in Organization model
- Test Connect flows with organization ownership

### Task 2.8: Data Migration Script
- Create migration to backfill organization_id for all existing records
- For each existing user, create a default organization (name: "#{user.name}'s Organization")
- Create organization membership (role: owner) for user
- Update all user's data to point to new organization
- Verify data integrity after migration
- Add rollback capability

### Task 2.9: Add NOT NULL Constraints
- Create migration to add NOT NULL constraint to organization_id columns
- Remove old user_id columns (or keep for auditing with different name)
- Update schema documentation
- Verify all associations work correctly

## Phase 3: Current Context Management

### Task 3.1: Update Current Model for Organization Context
- Add attribute :organization to Current model
- Add attribute :membership to Current model
- Add organization= setter that also sets membership
- Add helper methods: organization_owner?, organization_admin?
- Update current.rb with proper delegation

### Task 3.2: Create OrganizationContext Concern
- Create app/controllers/concerns/organization_context.rb
- Add before_action :set_organization_context
- Read current_organization_id from session
- Set Current.organization and Current.membership
- Redirect to org selector if no context and multiple orgs exist
- Handle case where user has no organizations

### Task 3.3: Create OrganizationAuthorization Concern
- Create app/controllers/concerns/organization_authorization.rb
- Add require_organization_member method
- Add require_organization_admin method
- Add require_organization_owner method
- Add can_manage_billing? check
- Add authorization failure handling

### Task 3.4: Update ApplicationController
- Include OrganizationContext concern
- Include OrganizationAuthorization concern
- Add current_organization helper method
- Add organization switching helper methods
- Update authentication flow to handle organization context

## Phase 4: Organization Management UI

### Task 4.1: Create Organization Switcher Component
- Create app/views/shared/_organization_switcher.html.erb
- Add dropdown in navbar showing current organization name
- List all user's organizations with role badges
- Add "Switch to" action for each org (updates session)
- Add "Create Organization" link
- Style with Tailwind (match existing navbar style)
- Add Stimulus controller for dropdown interaction

### Task 4.2: Create Organizations Controller
- Create app/controllers/organizations_controller.rb
- Implement index: list all organizations user belongs to
- Implement new: form to create new organization
- Implement create: create org and set user as owner
- Implement show: organization dashboard/overview
- Implement update: update organization settings (admins only)
- Implement destroy: delete organization (owners only, with confirmations)
- Add proper authorization checks

### Task 4.3: Create Organization Views
- Create app/views/organizations/index.html.erb (list all orgs)
- Create app/views/organizations/new.html.erb (create org form)
- Create app/views/organizations/show.html.erb (org dashboard)
- Create app/views/organizations/edit.html.erb (org settings)
- Add empty states for users with no organizations
- Style consistently with existing UI

### Task 4.4: Create Organization Settings Page
- Create organization settings view with tabs
- General tab: name, slug, logo
- Billing tab: subscription management (if owner/billing_admin)
- Stripe Connect tab: onboarding status and settings
- Danger zone tab: delete organization (owner only)
- Add form validations and error handling

### Task 4.5: Create Team Members Management
- Create app/controllers/organization_members_controller.rb
- Implement index: list all members with roles
- Implement update: change member role (admins only)
- Implement destroy: remove member (admins only, can't remove owner)
- Create views for member management
- Add role change confirmations

### Task 4.6: Create Invitations System
- Create app/controllers/organization_invitations_controller.rb
- Implement new: invite member form (admins only)
- Implement create: send invitation email with token
- Implement show: accept/decline invitation page
- Implement accept: create membership, mark invitation accepted
- Implement destroy: revoke pending invitation
- Create invitation views and email templates

### Task 4.7: Add Organization Context to Navbar
- Update navbar to show current organization name
- Add organization switcher dropdown to navbar
- Show user's role in current organization
- Add visual indicator for current context
- Update mobile navbar with same functionality

## Phase 5: Controller Updates

### Task 5.1: Update MerchantProductsController for Organizations
- Replace all Current.user with Current.organization
- Update @products = Current.organization.products
- Add organization membership checks
- Update controller tests for organization context
- Verify all CRUD operations work with organization scope

### Task 5.2: Update MerchantCustomersController for Organizations
- Replace all Current.user with Current.organization
- Update @customers = Current.organization.customers
- Add organization membership checks
- Update controller tests for organization context
- Verify all CRUD operations work with organization scope

### Task 5.3: Update MerchantInvoicesController for Organizations
- Replace all Current.user with Current.organization
- Update @invoices = Current.organization.invoices
- Update InvoiceService to use organization
- Add organization membership checks
- Update controller tests for organization context

### Task 5.4: Update PlatformChargesController for Organizations
- Update to use Current.organization for transactions
- Update charge creation to use organization
- Update fee calculations for organization context
- Update controller tests

### Task 5.5: Update SettingsController for Organizations
- Move Stripe Connect settings to organization settings
- Keep user profile settings in user settings
- Update subscription management to use organization context
- Redirect billing to organization billing page

## Phase 6: Business Logic Updates

### Task 6.1: Move Subscription Logic to Organization
- Add pay_customer to Organization model
- Add subscribed? method to Organization
- Add on_trial? method to Organization
- Add on_trial_or_subscribed? method to Organization
- Update all subscription checks to use organization
- Update subscription controllers and views

### Task 6.2: Move Stripe Connect to Organization
- Add pay_merchant to Organization model
- Add merchant_onboarding_complete? to Organization
- Add can_accept_payments? to Organization
- Update ConnectedAccountsController for organization context
- Update all Connect checks to use organization

### Task 6.3: Update Platform Fee Calculations
- Move platform_fee_percentage to Organization
- Move calculate_platform_fee to Organization
- Update FeeCalculationService to accept organization
- Update fee configurations for organization context
- Update all fee calculations throughout app

### Task 6.4: Update Invoice Service for Organizations
- Update InvoiceService to use organization instead of user
- Update customer creation on Connect account for organization
- Update invoice metadata with organization_id
- Update webhook handlers for organization context
- Test invoice creation and sending

### Task 6.5: Update Product Sync Service for Organizations
- Update ProductSyncService to use organization
- Update product/price creation for organization Connect account
- Update sync logic for organization context
- Test product syncing

## Phase 7: B2B2C Customer Support

### Task 7.1: Link MerchantCustomers to Users
- Add optional user_id to merchant_customers table
- Add belongs_to :user, optional: true to MerchantCustomer
- Add has_many :customer_records to User (class_name: MerchantCustomer)
- Create method to link existing customer to user by email
- Add UI to show if customer has user account

### Task 7.2: Customer Sign-Up Flow
- Create customer_signups_controller.rb
- Implement sign-up form for customers
- Link customer record to newly created user
- Send welcome email to new customer user
- Create customer onboarding flow

### Task 7.3: Customer Context in UI
- Add "Customer View" context option
- Show organizations where user is a customer
- Allow switching between member orgs and customer orgs
- Different UI for customer vs member context
- Show invoices and purchase history for customers

## Phase 8: Routes and Navigation

### Task 8.1: Add Organization Routes
- Add resources :organizations with member routes
- Add organization switching route POST /organizations/:id/switch
- Add nested routes for members and invitations
- Add organization settings routes
- Update routes.rb with proper namespacing

### Task 8.2: Update Navigation for Organizations
- Update sidebar_helper.rb for organization context
- Add organization switcher to sidebar
- Update navigation items to show organization context
- Add organization settings link (admins only)
- Add team members link (admins only)

### Task 8.3: Add Onboarding Flow for First Organization
- Create organization onboarding controller
- Implement first-time setup wizard
- Create default organization for new users
- Guide users through initial setup
- Set organization context automatically

## Phase 9: Background Jobs Updates

### Task 9.1: Update Webhook Jobs for Organizations
- Update MerchantInvoiceWebhookJob to use organization_id
- Update ConnectedAccountWebhookJob for organization context
- Update ReferralRewardWebhookJob for organization context
- Update CreditApplicationWebhookJob for organization context
- Ensure all webhook handlers route to correct organization

### Task 9.2: Update Referral System for Organizations
- Update referral rewards to work at organization level
- Update referral tracking for organization context
- Update reward calculations for organization subscriptions
- Test referral flows with organizations

## Phase 10: Testing and Performance

### Task 10.1: Add Organization Scoping Tests
- Test data isolation between organizations
- Test that users can only access their organization's data
- Test authorization at organization level
- Test context switching
- Add integration tests for multi-org scenarios

### Task 10.2: Add Performance Optimizations
- Add composite indexes on (organization_id, ...) for all tables
- Optimize queries with eager loading of organization
- Add query performance tests
- Monitor N+1 queries in organization context
- Add database query monitoring

### Task 10.3: Add Security Tests
- Test cross-organization data leakage prevention
- Test authorization bypass attempts
- Test invitation token security
- Test role escalation prevention
- Add security-focused integration tests

## Phase 11: Documentation and Rollout

### Task 11.1: Update Documentation
- Document organization architecture
- Document multi-tenancy patterns used
- Document role-based access control
- Create user guide for organization management
- Create developer guide for organization scoping

### Task 11.2: Create Migration Guide
- Document migration process for existing users
- Create rollback procedures
- Document breaking changes
- Create admin tools for data migration
- Test migration on staging environment

### Task 11.3: Final Testing and Launch
- Run full test suite
- Perform end-to-end testing of all flows
- Test with production-like data volume
- Performance testing under load
- Deploy to production with monitoring
