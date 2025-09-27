class CreateReferReferrals < ActiveRecord::Migration[8.1]
  def change
    create_table :refer_referrals, id: :string, default: -> { "uuid()" } do |t|
      t.belongs_to :referrer, type: :string, polymorphic: true, null: false
      t.belongs_to :referee, type: :string, polymorphic: true, null: false
      t.belongs_to :referral_code, type: :string

      t.timestamps
    end
  end
end
