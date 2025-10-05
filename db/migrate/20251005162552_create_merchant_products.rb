# frozen_string_literal: true

# Migration to create merchant products table
# Stores product/service catalog for each merchant
class CreateMerchantProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :merchant_products, id: :string, default: -> { "uuid()" } do |t|
      t.string :user_id, null: false
      t.string :name, null: false
      t.text :description
      t.integer :default_price_cents, null: false
      t.string :unit_type, default: "item" # item, hour, day, month, etc.
      t.string :tax_code
      t.string :stripe_product_id
      t.string :stripe_price_id
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :merchant_products, :user_id
    add_index :merchant_products, :stripe_product_id
    add_index :merchant_products, [ :user_id, :active ]
  end
end
