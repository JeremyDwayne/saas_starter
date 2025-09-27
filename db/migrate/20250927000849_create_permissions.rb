class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions, id: :string, default: -> { "uuid()" } do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description
      t.string :resource, null: false
      t.string :action, null: false

      t.timestamps
    end

    add_index :permissions, [ :resource, :action ], unique: true
  end
end
