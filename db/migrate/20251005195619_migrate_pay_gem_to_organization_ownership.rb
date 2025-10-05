class MigratePayGemToOrganizationOwnership < ActiveRecord::Migration[8.1]
  def up
    # Find all users who own Pay customers or merchants
    user_ids = Pay::Customer.where(owner_type: "User").pluck(:owner_id).uniq +
               Pay::Merchant.where(owner_type: "User").pluck(:owner_id).uniq
    user_ids.uniq!

    # For each user, create or find their default organization
    user_ids.each do |user_id|
      user = User.find_by(id: user_id)
      next unless user

      # Find or create the user's default organization
      organization = Organization.find_or_create_by!(owner_id: user_id) do |org|
        org.name = "#{user.name || user.email_address}'s Organization"
      end

      # Migrate Pay customers
      Pay::Customer.where(owner_type: "User", owner_id: user_id).update_all(
        owner_type: "Organization",
        owner_id: organization.id
      )

      # Migrate Pay merchants
      Pay::Merchant.where(owner_type: "User", owner_id: user_id).update_all(
        owner_type: "Organization",
        owner_id: organization.id
      )
    end
  end

  def down
    # Reverse migration: move ownership back to users
    Organization.find_each do |organization|
      # Migrate Pay customers back to user
      Pay::Customer.where(owner_type: "Organization", owner_id: organization.id).update_all(
        owner_type: "User",
        owner_id: organization.owner_id
      )

      # Migrate Pay merchants back to user
      Pay::Merchant.where(owner_type: "Organization", owner_id: organization.id).update_all(
        owner_type: "User",
        owner_id: organization.owner_id
      )
    end
  end
end
