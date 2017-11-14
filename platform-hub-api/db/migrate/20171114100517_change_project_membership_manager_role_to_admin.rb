class ChangeProjectMembershipManagerRoleToAdmin < ActiveRecord::Migration[5.0]
  def up
    ProjectMembership.connection.execute("UPDATE project_memberships SET role = 'admin' WHERE role = 'manager'")
  end

  def down
    ProjectMembership.connection.execute("UPDATE project_memberships SET role = 'manager' WHERE role = 'admin'")
  end
end
