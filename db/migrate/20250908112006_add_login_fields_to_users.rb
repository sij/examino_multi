class AddLoginFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :login_ip, :string
    add_column :users, :login_at, :datetime
  end
end