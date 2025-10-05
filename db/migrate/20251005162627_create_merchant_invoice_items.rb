# frozen_string_literal: true

# Migration to create merchant invoice items table
# Stores line items for each invoice
class CreateMerchantInvoiceItems < ActiveRecord::Migration[8.1]
  def change
    create_table :merchant_invoice_items, id: :string, default: -> { "uuid()" } do |t|
      t.string :invoice_id, null: false
      t.string :product_id # nullable for custom line items
      t.string :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, default: 1.0
      t.integer :unit_price_cents, null: false
      t.integer :amount_cents, null: false
      t.string :stripe_invoice_item_id

      t.timestamps
    end

    add_index :merchant_invoice_items, :invoice_id
    add_index :merchant_invoice_items, :product_id
    add_index :merchant_invoice_items, :stripe_invoice_item_id
  end
end
