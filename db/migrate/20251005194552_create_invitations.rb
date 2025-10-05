class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations, id: :string, default: -> { "uuid()" } do |t|
      t.string :email, null: false
      t.integer :role, null: false, default: 1
      t.string :token, null: false
      t.string :organization_id, null: false
      t.string :invited_by_id, null: false

      t.timestamps
    end

    add_index :invitations, :email, unique: true
    add_index :invitations, :token, unique: true
    add_index :invitations, :organization_id
    add_index :invitations, :invited_by_id
  end
end
