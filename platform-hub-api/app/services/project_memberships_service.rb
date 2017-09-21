module ProjectMembershipsService
  extend self

  def is_user_a_member_of_project? project_id, user_id
    scope.exists? project_id: project_id, user_id: user_id
  end

  def is_user_a_manager_of_project? project_id, user_id
    manager_scope.exists? project_id: project_id, user_id: user_id
  end

  def is_user_a_manager_of_any_project? user_id
    manager_scope.exists? user_id: user_id
  end

  def is_user_a_manager_of_a_common_project? user, target_user
    # Find common projects between the two users
    target_user_projects = target_user.project_ids
    user_projects = user.project_ids
    common_projects = target_user_projects & user_projects

    # Now check to see if user is a manager of any of these common projects
    manager_scope.exists? project_id: common_projects, user_id: user.id
  end

  private

  def scope
    ProjectMembership
  end

  def manager_scope
    ProjectMembership.manager
  end

end
