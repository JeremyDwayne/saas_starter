class CreateAnnouncements < ActiveRecord::Migration[8.1]
  def change
    create_table :announcements, id: :string, default: -> { "uuid()" } do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.integer :announcement_type, null: false, default: 0
      t.datetime :published_at

      t.timestamps
    end

    add_index :announcements, :published_at
    add_index :announcements, :announcement_type
  end
end
