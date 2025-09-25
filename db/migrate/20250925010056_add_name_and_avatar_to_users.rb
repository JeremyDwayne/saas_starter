class AddNameAndAvatarToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string
  end

  def down
    remove_column :users, :name
    remove_column :users, :avatar_url
  end
end
