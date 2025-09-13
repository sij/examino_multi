class CreateOwnersWithoutId < ActiveRecord::Migration[8.0]
  def change
    create_table :owners, id: false do |t|
      t.integer :id, primary_key: true   
      t.string :name
      t.string :gruppo
      t.timestamps
    end
  end
end
