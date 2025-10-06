class CreateOnboardings < ActiveRecord::Migration[8.1]
  def change
    create_table :onboardings, id: :string, default: -> { "uuid()" } do |t|
      t.string :organization_id, null: false
      t.boolean :profile_completed, default: false, null: false
      t.boolean :organization_details_completed, default: false, null: false
      t.boolean :platform_configured, default: false, null: false
      t.boolean :stripe_connect_completed, default: false, null: false
      t.datetime :completed_at
      t.integer :current_step, default: 0, null: false

      t.timestamps
    end
    add_index :onboardings, :organization_id, unique: true
  end
end
