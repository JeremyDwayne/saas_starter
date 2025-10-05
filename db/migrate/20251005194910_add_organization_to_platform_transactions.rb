class AddOrganizationToPlatformTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :platform_transactions, :organization_id, :string
    add_index :platform_transactions, :organization_id
  end
end
