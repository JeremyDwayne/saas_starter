class CreateOmniAuthIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :omni_auth_identities do |t|
      t.string :uid
      t.string :provider
      t.string :user_id, null: false

      t.timestamps
    end
    add_index :omni_auth_identities, :user_id
  end
end
