class EnforceOrganizationIdConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :merchant_customers, :organization_id, false
    change_column_null :merchant_products, :organization_id, false
    change_column_null :merchant_invoices, :organization_id, false
    change_column_null :platform_transactions, :organization_id, false
    change_column_null :custom_platform_fees, :organization_id, false
  end
end
