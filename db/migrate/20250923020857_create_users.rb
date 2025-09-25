class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :string, default: -> { "uuid()" } do |t|
      t.string :email_address, null: false, index: { unique: true }
      t.string :password_digest, null: false

      t.timestamps
    end
  end
end
