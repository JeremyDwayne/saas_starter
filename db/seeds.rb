# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Skip seeding in test environment to avoid conflicts with fixtures
return if Rails.env.test?

puts "Seeding roles and permissions..."

# Create roles
admin_role = Role.find_or_create_by!(name: "admin") do |role|
  role.description = "Full system administration access"
end

user_role = Role.find_or_create_by!(name: "user") do |role|
  role.description = "Standard user access"
end

# Create permissions
admin_permissions = [
  { name: "admin_dashboard_access", description: "Access to admin dashboard", resource: "dashboard", action: "access" },
  { name: "manage_users", description: "Create, read, update, delete users", resource: "users", action: "manage" },
  { name: "manage_roles", description: "Create, read, update, delete roles", resource: "roles", action: "manage" },
  { name: "manage_permissions", description: "Create, read, update, delete permissions", resource: "permissions", action: "manage" },
  { name: "view_analytics", description: "View system analytics and reports", resource: "analytics", action: "view" },
  { name: "manage_billing", description: "Manage billing and subscriptions", resource: "billing", action: "manage" }
]

user_permissions = [
  { name: "view_profile", description: "View own profile", resource: "profile", action: "view" },
  { name: "edit_profile", description: "Edit own profile", resource: "profile", action: "edit" },
  { name: "manage_subscription", description: "Manage own subscription", resource: "subscription", action: "manage" }
]

# Create all permissions
all_permissions = admin_permissions + user_permissions
all_permissions.each do |perm_data|
  Permission.find_or_create_by!(
    name: perm_data[:name],
    resource: perm_data[:resource],
    action: perm_data[:action]
  ) do |permission|
    permission.description = perm_data[:description]
  end
end

# Assign permissions to roles
admin_role.permissions = Permission.all
user_role.permissions = Permission.where(name: user_permissions.map { |p| p[:name] })

puts "Created #{Role.count} roles and #{Permission.count} permissions"
puts "Roles: #{Role.pluck(:name).join(', ')}"

puts "Seeding referral configurations..."

# Create default referral configuration
default_config = ReferralConfiguration.find_or_create_by!(name: "Default Configuration") do |config|
  config.reward_percentage = 10.0
  config.enabled = true
  config.description = "Default referral reward configuration - 10% credit for successful referrals"
end

puts "Created referral configuration: #{default_config.name} (#{default_config.reward_percentage}% rewards)"

puts "Seeding platform fee configurations..."

# Create platform fee configurations for each subscription tier
fee_configs = [
  {
    subscription_tier: "personal",
    fee_percentage: 7.0,
    minimum_fee_cents: 50,
    active: true,
    description: "Personal plan - highest fee percentage"
  },
  {
    subscription_tier: "professional",
    fee_percentage: 5.0,
    minimum_fee_cents: 50,
    active: true,
    description: "Professional plan - medium fee percentage"
  },
  {
    subscription_tier: "enterprise",
    fee_percentage: 3.0,
    minimum_fee_cents: 50,
    active: true,
    description: "Enterprise plan - lowest fee percentage"
  },
  {
    subscription_tier: "none",
    fee_percentage: 7.0,
    minimum_fee_cents: 50,
    active: true,
    description: "No subscription - default fee percentage"
  }
]

fee_configs.each do |config_data|
  PlatformFeeConfiguration.find_or_create_by!(subscription_tier: config_data[:subscription_tier]) do |config|
    config.fee_percentage = config_data[:fee_percentage]
    config.minimum_fee_cents = config_data[:minimum_fee_cents]
    config.active = config_data[:active]
  end
end

puts "Created #{PlatformFeeConfiguration.count} platform fee configurations"
puts "Fee tiers: #{PlatformFeeConfiguration.pluck(:subscription_tier, :fee_percentage).map { |t, f| "#{t}: #{f}%" }.join(', ')}"
