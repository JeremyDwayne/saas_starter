class CreateReferralConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :referral_configurations, id: :string, default: -> { "uuid()" } do |t|
      t.decimal :reward_percentage, precision: 5, scale: 2, null: false, default: 10.0, comment: "Percentage of subscription amount to reward (e.g., 10.0 for 10%)"
      t.boolean :enabled, null: false, default: true
      t.integer :max_credits_per_referral, comment: "Maximum credit amount per referral in cents (nil = no limit)"
      t.integer :credit_expiry_days, comment: "Days after which credits expire (nil = no expiry)"
      t.string :name, null: false, default: "Default Configuration"
      t.text :description

      t.timestamps

      t.index [ :enabled ]
    end
  end
end
