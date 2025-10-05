# frozen_string_literal: true

# Migration to create merchant customers table
# Stores customer information for each merchant's invoicing needs
class CreateMerchantCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :merchant_customers, id: :string, default: -> { "uuid()" } do |t|
      t.string :user_id, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal_code
      t.string :country, default: "US"
      t.string :stripe_customer_id
      t.text :notes

      t.timestamps
    end

    add_index :merchant_customers, :user_id
    add_index :merchant_customers, :stripe_customer_id
    add_index :merchant_customers, [ :user_id, :email ]
  end
end
