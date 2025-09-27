class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions, id: :string, default: -> { "uuid()" } do |t|
      t.string :role_id, null: false
      t.string :permission_id, null: false

      t.timestamps
    end

    add_index :role_permissions, :role_id
    add_index :role_permissions, :permission_id
    add_index :role_permissions, [ :role_id, :permission_id ], unique: true

    add_foreign_key :role_permissions, :roles
    add_foreign_key :role_permissions, :permissions
  end
end
