class CreateReferReferralCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :refer_referral_codes, id: :string, default: -> { "uuid()" } do |t|
      t.belongs_to :referrer, type: :string, polymorphic: true, null: false
      t.string :code, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
