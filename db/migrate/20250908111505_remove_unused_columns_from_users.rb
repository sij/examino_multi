class RemoveUnusedColumnsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :tipo, :integer if column_exists?(:users, :tipo)
    remove_column :users, :auth_import, :integer if column_exists?(:users, :auth_import)
    remove_column :users, :sw, :string if column_exists?(:users, :sw)
  end
end
