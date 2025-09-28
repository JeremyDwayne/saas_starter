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

ActiveRecord::Schema[8.1].define(version: 2025_09_28_020319) do
  create_table "omni_auth_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index [ "user_id" ], name: "index_omni_auth_identities_on_user_id"
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

  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "refer_visits", "refer_referral_codes", column: "referral_code_id"
  add_foreign_key "referral_rewards", "users", column: "referee_id"
  add_foreign_key "referral_rewards", "users", column: "referrer_id"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
