class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.string :user_id, null: false
      t.string :ip_address
      t.string :user_agent
      t.string :source


      t.timestamps
    end
    add_index :sessions, :user_id
  end
end
