class MakeOwnerIdNotNullInGiDetailsAndUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :g1_details, :owner_id, false
    change_column_null :users, :owner_id, false
  end
end