module ProjectManagersService

  def self.is_user_a_manager_of_specified_project? project_id, user_id
    ProjectMembership.exists? project_id: project_id, user_id: user_id, role: :manager
  end

  def self.is_user_a_manager_of_any_project? user_id
    ProjectMembership.exists? user_id: user_id, role: :manager
  end

end
