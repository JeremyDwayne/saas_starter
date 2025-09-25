class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.string :user_id, null: false, index: true
      t.string :ip_address
      t.string :user_agent
      t.string :source


      t.timestamps
    end
  end
end
