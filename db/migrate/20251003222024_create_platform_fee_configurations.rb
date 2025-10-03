class CreatePlatformFeeConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_fee_configurations, id: :string, default: -> { "uuid()" } do |t|
      t.string :subscription_tier, null: false
      t.decimal :fee_percentage, precision: 5, scale: 2, null: false
      t.integer :minimum_fee_cents
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :platform_fee_configurations, :subscription_tier, unique: true
    add_index :platform_fee_configurations, :active
  end
end
