class AddOrganizationToMerchantCustomers < ActiveRecord::Migration[8.1]
  def change
    add_column :merchant_customers, :organization_id, :string
    add_index :merchant_customers, :organization_id
  end
end
