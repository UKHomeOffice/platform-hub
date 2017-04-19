class AddScopesToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :is_managerial, :boolean, default: true
    add_column :users, :is_technical, :boolean, default: true
  end
end
