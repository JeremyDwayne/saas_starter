class BackfillOrganizationIdForBusinessData < ActiveRecord::Migration[8.1]
  def up
    # Get all users who have business data but no organization
    User.find_each do |user|
      # Find or create the user's default organization
      organization = Organization.find_or_create_by!(owner_id: user.id) do |org|
        org.name = "#{user.name || user.email_address}'s Organization"
      end

      # Create owner membership if it doesn't exist
      OrganizationMembership.find_or_create_by!(
        user: user,
        organization: organization
      ) do |membership|
        membership.role = :admin
      end

      # Update all business data with organization_id
      MerchantCustomer.where(user_id: user.id, organization_id: nil).update_all(organization_id: organization.id)
      MerchantProduct.where(user_id: user.id, organization_id: nil).update_all(organization_id: organization.id)
      MerchantInvoice.where(user_id: user.id, organization_id: nil).update_all(organization_id: organization.id)
      PlatformTransaction.where(merchant_id: user.id, organization_id: nil).update_all(organization_id: organization.id)
      CustomPlatformFee.where(user_id: user.id, organization_id: nil).update_all(organization_id: organization.id)
    end
  end

  def down
    # Clear organization_id values (reversible)
    MerchantCustomer.update_all(organization_id: nil)
    MerchantProduct.update_all(organization_id: nil)
    MerchantInvoice.update_all(organization_id: nil)
    PlatformTransaction.update_all(organization_id: nil)
    CustomPlatformFee.update_all(organization_id: nil)
  end
end
