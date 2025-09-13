class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :info
      t.string :name
      t.boolean :enabled, default: true
      t.references :bet_point
      t.references :role, foreign_key: true

      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :name, unique: true
  end
end
