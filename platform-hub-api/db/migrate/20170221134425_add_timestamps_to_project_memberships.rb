class AddTimestampsToProjectMemberships < ActiveRecord::Migration[5.0]
  def change
    add_column :project_memberships, :created_at, :datetime
    add_column :project_memberships, :updated_at, :datetime
  end
end
