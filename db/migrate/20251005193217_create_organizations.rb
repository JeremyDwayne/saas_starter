class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations, id: :string, default: -> { "uuid()" } do |t|
      t.string :name, null: false
      t.string :slug
      t.string :owner_id
      t.json :settings, default: {}

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
    add_index :organizations, :owner_id
  end
end
