# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_10_05_201032) do
  create_table "custom_platform_fees", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "expires_at"
    t.decimal "fee_percentage", precision: 5, scale: 2, null: false
    t.integer "minimum_fee_cents"
    t.string "notes"
    t.string "organization_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index [ "expires_at" ], name: "index_custom_platform_fees_on_expires_at"
    t.index [ "organization_id" ], name: "index_custom_platform_fees_on_organization_id"
    t.index [ "user_id" ], name: "index_custom_platform_fees_on_user_id", unique: true
  end

  create_table "invitations", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "invited_by_id", null: false
    t.string "organization_id", null: false
    t.integer "role", default: 1, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_invitations_on_email", unique: true
    t.index [ "invited_by_id" ], name: "index_invitations_on_invited_by_id"
    t.index [ "organization_id" ], name: "index_invitations_on_organization_id"
    t.index [ "token" ], name: "index_invitations_on_token", unique: true
  end

  create_table "merchant_customers", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "country", default: "US"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "organization_id", null: false
    t.string "phone"
    t.string "postal_code"
    t.string "state"
    t.string "stripe_customer_id"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index [ "organization_id" ], name: "index_merchant_customers_on_organization_id"
    t.index [ "stripe_customer_id" ], name: "index_merchant_customers_on_stripe_customer_id"
    t.index [ "user_id", "email" ], name: "index_merchant_customers_on_user_id_and_email"
    t.index [ "user_id" ], name: "index_merchant_customers_on_user_id"
  end

  create_table "merchant_invoice_items", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "invoice_id", null: false
    t.string "product_id"
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0"
    t.string "stripe_invoice_item_id"
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index [ "invoice_id" ], name: "index_merchant_invoice_items_on_invoice_id"
    t.index [ "product_id" ], name: "index_merchant_invoice_items_on_product_id"
    t.index [ "stripe_invoice_item_id" ], name: "index_merchant_invoice_items_on_stripe_invoice_item_id"
  end

  create_table "merchant_invoices", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.integer "application_fee_cents", default: 0
    t.datetime "created_at", null: false
    t.string "customer_id", null: false
    t.integer "days_until_due", default: 30
    t.date "due_date"
    t.text "footer_text"
    t.string "invoice_number", null: false
    t.text "notes"
    t.string "organization_id", null: false
    t.datetime "paid_at"
    t.datetime "sent_at"
    t.string "status", default: "draft"
    t.string "stripe_invoice_id"
    t.integer "subtotal_cents", default: 0
    t.integer "tax_cents", default: 0
    t.integer "total_cents", default: 0
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.datetime "voided_at"
    t.index [ "customer_id" ], name: "index_merchant_invoices_on_customer_id"
    t.index [ "organization_id" ], name: "index_merchant_invoices_on_organization_id"
    t.index [ "status" ], name: "index_merchant_invoices_on_status"
    t.index [ "stripe_invoice_id" ], name: "index_merchant_invoices_on_stripe_invoice_id"
    t.index [ "user_id", "invoice_number" ], name: "index_merchant_invoices_on_user_id_and_invoice_number", unique: true
    t.index [ "user_id" ], name: "index_merchant_invoices_on_user_id"
  end

  create_table "merchant_products", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "default_price_cents", null: false
    t.text "description"
    t.string "name", null: false
    t.string "organization_id", null: false
    t.string "stripe_price_id"
    t.string "stripe_product_id"
    t.string "tax_code"
    t.string "unit_type", default: "item"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index [ "organization_id" ], name: "index_merchant_products_on_organization_id"
    t.index [ "stripe_product_id" ], name: "index_merchant_products_on_stripe_product_id"
    t.index [ "user_id", "active" ], name: "index_merchant_products_on_user_id_and_active"
    t.index [ "user_id" ], name: "index_merchant_products_on_user_id"
  end

  create_table "omni_auth_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index [ "user_id" ], name: "index_omni_auth_identities_on_user_id"
  end

  create_table "organization_memberships", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "organization_id", null: false
    t.integer "role", default: 1, null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index [ "organization_id" ], name: "index_organization_memberships_on_organization_id"
    t.index [ "user_id", "organization_id" ], name: "index_org_memberships_on_user_and_org", unique: true
    t.index [ "user_id" ], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "owner_id"
    t.json "settings", default: {}
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index [ "owner_id" ], name: "index_organizations_on_owner_id"
    t.index [ "slug" ], name: "index_organizations_on_slug", unique: true
  end

  create_table "pay_charges", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "amount_refunded"
    t.integer "application_fee_amount"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "customer_id", null: false
    t.json "data"
    t.json "metadata"
    t.json "object"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.string "subscription_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index [ "customer_id", "processor_id" ], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index [ "subscription_id" ], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.boolean "default"
    t.datetime "deleted_at"
    t.json "object"
    t.string "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index [ "owner_type", "owner_id", "deleted_at" ], name: "pay_customer_owner_index", unique: true
    t.index [ "processor", "processor_id" ], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.boolean "default"
    t.string "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index [ "owner_type", "owner_id", "processor" ], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_id", null: false
    t.json "data"
    t.boolean "default"
    t.string "payment_method_type"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index [ "customer_id", "processor_id" ], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.string "customer_id", null: false
    t.json "data"
    t.datetime "ends_at"
    t.json "metadata"
    t.boolean "metered"
    t.string "name", null: false
    t.json "object"
    t.string "pause_behavior"
    t.datetime "pause_resumes_at"
    t.datetime "pause_starts_at"
    t.string "payment_method_id"
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.string "stripe_account"
    t.datetime "trial_ends_at"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index [ "customer_id", "processor_id" ], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index [ "metered" ], name: "index_pay_subscriptions_on_metered"
    t.index [ "pause_starts_at" ], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "event"
    t.string "event_type"
    t.string "processor"
    t.datetime "updated_at", null: false
  end

  create_table "permissions", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index [ "name" ], name: "index_permissions_on_name", unique: true
    t.index [ "resource", "action" ], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "platform_fee_configurations", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.decimal "fee_percentage", precision: 5, scale: 2, null: false
    t.integer "minimum_fee_cents"
    t.string "subscription_tier", null: false
    t.datetime "updated_at", null: false
    t.index [ "active" ], name: "index_platform_fee_configurations_on_active"
    t.index [ "subscription_tier" ], name: "index_platform_fee_configurations_on_subscription_tier", unique: true
  end

  create_table "platform_transactions", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.integer "application_fee_cents", null: false
    t.integer "charge_amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "description"
    t.decimal "fee_percentage_applied", precision: 5, scale: 2
    t.string "merchant_id", null: false
    t.json "metadata"
    t.string "organization_id", null: false
    t.string "status", default: "succeeded"
    t.string "stripe_charge_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "created_at" ], name: "index_platform_transactions_on_created_at"
    t.index [ "merchant_id" ], name: "index_platform_transactions_on_merchant_id"
    t.index [ "organization_id" ], name: "index_platform_transactions_on_organization_id"
    t.index [ "status" ], name: "index_platform_transactions_on_status"
    t.index [ "stripe_charge_id" ], name: "index_platform_transactions_on_stripe_charge_id", unique: true
  end

  create_table "refer_referral_codes", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.integer "referrals_count", default: 0
    t.string "referrer_id", null: false
    t.string "referrer_type", null: false
    t.datetime "updated_at", null: false
    t.integer "visits_count", default: 0
    t.index [ "code" ], name: "index_refer_referral_codes_on_code", unique: true
    t.index [ "referrer_type", "referrer_id" ], name: "index_refer_referral_codes_on_referrer"
  end

  create_table "refer_referrals", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "referee_id", null: false
    t.string "referee_type", null: false
    t.string "referral_code_id"
    t.string "referrer_id", null: false
    t.string "referrer_type", null: false
    t.datetime "updated_at", null: false
    t.index [ "referee_type", "referee_id" ], name: "index_refer_referrals_on_referee"
    t.index [ "referral_code_id" ], name: "index_refer_referrals_on_referral_code_id"
    t.index [ "referrer_type", "referrer_id" ], name: "index_refer_referrals_on_referrer"
  end

  create_table "refer_visits", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip"
    t.string "referral_code_id", null: false
    t.text "referrer"
    t.string "referring_domain"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.index [ "referral_code_id" ], name: "index_refer_visits_on_referral_code_id"
  end

  create_table "referral_configurations", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "credit_expiry_days"
    t.text "description"
    t.boolean "enabled", default: true, null: false
    t.integer "max_credits_per_referral"
    t.string "name", default: "Default Configuration", null: false
    t.decimal "reward_percentage", precision: 5, scale: 2, default: "10.0", null: false
    t.datetime "updated_at", null: false
    t.index [ "enabled" ], name: "index_referral_configurations_on_enabled"
  end

  create_table "referral_rewards", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.datetime "earned_at", null: false
    t.text "notes"
    t.string "referee_id", null: false
    t.string "referrer_id", null: false
    t.string "status", default: "pending", null: false
    t.string "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index [ "earned_at" ], name: "index_referral_rewards_on_earned_at"
    t.index [ "referee_id" ], name: "index_referral_rewards_on_referee_id"
    t.index [ "referrer_id" ], name: "index_referral_rewards_on_referrer_id"
    t.index [ "status" ], name: "index_referral_rewards_on_status"
    t.index [ "subscription_id" ], name: "index_referral_rewards_on_subscription_id"
  end

  create_table "role_permissions", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission_id", null: false
    t.string "role_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "permission_id" ], name: "index_role_permissions_on_permission_id"
    t.index [ "role_id", "permission_id" ], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index [ "role_id" ], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index [ "name" ], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "source"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.string "user_id", null: false
    t.index [ "user_id" ], name: "index_sessions_on_user_id"
  end

  create_table "user_roles", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index [ "role_id" ], name: "index_user_roles_on_role_id"
    t.index [ "user_id", "role_id" ], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index [ "user_id" ], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :string, default: -> { "uuid()" }, force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index [ "email_address" ], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "custom_platform_fees", "users"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "platform_transactions", "users", column: "merchant_id"
  add_foreign_key "refer_visits", "refer_referral_codes", column: "referral_code_id"
  add_foreign_key "referral_rewards", "users", column: "referee_id"
  add_foreign_key "referral_rewards", "users", column: "referrer_id"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
