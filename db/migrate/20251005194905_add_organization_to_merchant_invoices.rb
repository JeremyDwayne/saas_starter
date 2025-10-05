class AddOrganizationToMerchantInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :merchant_invoices, :organization_id, :string
    add_index :merchant_invoices, :organization_id
  end
end
