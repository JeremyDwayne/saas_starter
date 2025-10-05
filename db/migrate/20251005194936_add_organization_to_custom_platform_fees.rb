class AddOrganizationToCustomPlatformFees < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_platform_fees, :organization_id, :string
    add_index :custom_platform_fees, :organization_id
  end
end
