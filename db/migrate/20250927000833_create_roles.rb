class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles, id: :string, default: -> { "uuid()" } do |t|
      t.string :name, null: false, index: { unique: true }
      t.text :description

      t.timestamps
    end
  end
end
