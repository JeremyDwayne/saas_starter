class AddImpersonationToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :impersonator_id, :string
    add_column :sessions, :impersonated_role, :string
    add_index :sessions, :impersonator_id
  end
end
