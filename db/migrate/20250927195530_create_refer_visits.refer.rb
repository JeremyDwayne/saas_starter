class CreateReferVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :refer_visits, id: :string, default: -> { "uuid()" } do |t|
      t.belongs_to :referral_code, null: false, type: :string, foreign_key: { to_table: :refer_referral_codes }
      t.string :ip
      t.text :user_agent
      t.text :referrer
      t.string :referring_domain

      t.timestamps
    end

    add_column :refer_referral_codes, :referrals_count, :integer, default: 0
    add_column :refer_referral_codes, :visits_count, :integer, default: 0
    add_column :refer_referrals, :completed_at, :datetime
  end
end
