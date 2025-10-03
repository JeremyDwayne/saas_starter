class CreateCustomPlatformFees < ActiveRecord::Migration[8.1]
  def change
    create_table :custom_platform_fees, id: :string, default: -> { "uuid()" } do |t|
      t.string :user_id, null: false
      t.decimal :fee_percentage, precision: 5, scale: 2, null: false
      t.integer :minimum_fee_cents
      t.string :notes
      t.date :expires_at

      t.timestamps
    end

    add_foreign_key :custom_platform_fees, :users
    add_index :custom_platform_fees, :user_id, unique: true
    add_index :custom_platform_fees, :expires_at
  end
end
