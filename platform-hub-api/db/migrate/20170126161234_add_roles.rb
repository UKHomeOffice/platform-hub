class AddRoles < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :role, :string
    add_column :project_memberships, :role, :string

    add_index :users, :role
  end
end
