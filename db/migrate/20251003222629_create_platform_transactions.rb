class CreatePlatformTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_transactions, id: :string, default: -> { "uuid()" } do |t|
      t.string :merchant_id, null: false
      t.string :stripe_charge_id, null: false
      t.integer :charge_amount_cents, null: false
      t.integer :application_fee_cents, null: false
      t.decimal :fee_percentage_applied, precision: 5, scale: 2
      t.string :customer_email
      t.string :description
      t.json :metadata
      t.string :status, default: "succeeded"

      t.timestamps
    end

    add_foreign_key :platform_transactions, :users, column: :merchant_id
    add_index :platform_transactions, :merchant_id
    add_index :platform_transactions, :stripe_charge_id, unique: true
    add_index :platform_transactions, :status
    add_index :platform_transactions, :created_at
  end
end
