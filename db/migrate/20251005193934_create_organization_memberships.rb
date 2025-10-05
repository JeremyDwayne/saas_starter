class CreateOrganizationMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_memberships, id: :string, default: -> { "uuid()" } do |t|
      t.string :user_id, null: false
      t.string :organization_id, null: false
      t.integer :role, null: false, default: 1

      t.timestamps
    end

    add_index :organization_memberships, [ :user_id, :organization_id ], unique: true, name: "index_org_memberships_on_user_and_org"
    add_index :organization_memberships, :user_id
    add_index :organization_memberships, :organization_id
  end
end
