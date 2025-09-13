class CreateSelfAdvances < ActiveRecord::Migration[8.0]
  def change
    create_table :self_advances do |t|
      t.integer :num_term

      t.timestamps
    end
  end
end
