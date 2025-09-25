class CreateOmniAuthIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :omni_auth_identities do |t|
      t.string :uid
      t.string :provider
      t.string :user_id, null: false, index: true

      t.timestamps
    end
  end
end
