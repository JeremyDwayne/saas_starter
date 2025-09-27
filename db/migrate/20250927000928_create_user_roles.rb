class CreateUserRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_roles, id: :string, default: -> { "uuid()" } do |t|
      t.string :user_id, null: false
      t.string :role_id, null: false

      t.timestamps
    end

    add_index :user_roles, :user_id
    add_index :user_roles, :role_id
    add_index :user_roles, [ :user_id, :role_id ], unique: true

    add_foreign_key :user_roles, :users
    add_foreign_key :user_roles, :roles
  end
end
