class AddOwnerToG1DetailsAndUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :g1_details, :owner, null: true, foreign_key: true
    add_reference :users, :owner, null: true, foreign_key: true
  end
end