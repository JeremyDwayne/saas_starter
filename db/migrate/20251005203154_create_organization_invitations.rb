class CreateOrganizationInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_invitations, id: { type: :string, default: -> { "uuid()" } } do |t|
      t.references :organization, null: false, foreign_key: true, type: :string
      t.string :email, null: false
      t.string :token, null: false
      t.string :role, null: false, default: "member"
      t.string :status, null: false, default: "pending"
      t.references :invited_by, null: false, foreign_key: { to_table: :users }, type: :string
      t.datetime :expires_at, null: false

      t.timestamps

      t.index :token, unique: true
      t.index :email
      t.index [ :organization_id, :email ], unique: true, where: "status = 'pending'"
    end
  end
end
