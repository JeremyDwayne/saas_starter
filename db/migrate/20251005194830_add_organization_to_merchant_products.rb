class AddOrganizationToMerchantProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :merchant_products, :organization_id, :string
    add_index :merchant_products, :organization_id
  end
end
