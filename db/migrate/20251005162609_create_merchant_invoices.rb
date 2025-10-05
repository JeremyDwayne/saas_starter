# frozen_string_literal: true

# Migration to create merchant invoices table
# Stores invoices created by merchants for their customers
class CreateMerchantInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :merchant_invoices, id: :string, default: -> { "uuid()" } do |t|
      t.string :user_id, null: false
      t.string :customer_id, null: false
      t.string :invoice_number, null: false
      t.string :status, default: "draft" # draft, open, paid, void, uncollectible
      t.date :due_date
      t.integer :days_until_due, default: 30
      t.string :stripe_invoice_id
      t.integer :subtotal_cents, default: 0
      t.integer :tax_cents, default: 0
      t.integer :total_cents, default: 0
      t.integer :application_fee_cents, default: 0
      t.text :notes
      t.text :footer_text
      t.datetime :sent_at
      t.datetime :paid_at
      t.datetime :voided_at

      t.timestamps
    end

    add_index :merchant_invoices, :user_id
    add_index :merchant_invoices, :customer_id
    add_index :merchant_invoices, :stripe_invoice_id
    add_index :merchant_invoices, :status
    add_index :merchant_invoices, [ :user_id, :invoice_number ], unique: true
  end
end
