class CreateReferralRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :referral_rewards, id: :string, default: -> { "uuid()" } do |t|
      t.string :referrer_id, null: false
      t.string :referee_id, null: false
      t.string :subscription_id, null: false
      t.integer :amount, null: false, comment: "Amount in cents"
      t.string :status, null: false, default: "pending"
      t.datetime :earned_at, null: false
      t.datetime :used_at
      t.text :notes

      t.timestamps

      t.index [ :referrer_id ]
      t.index [ :referee_id ]
      t.index [ :subscription_id ]
      t.index [ :status ]
      t.index [ :earned_at ]
    end

    add_foreign_key :referral_rewards, :users, column: :referrer_id
    add_foreign_key :referral_rewards, :users, column: :referee_id
  end
end
