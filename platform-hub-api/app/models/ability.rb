class Ability
  include CanCan::Ability

  def initialize(user)

    can :manage, :all if user.admin?


    project_manager_of_specified_project_checker = -> (project) do
      ProjectManagersService.is_user_a_manager_of_specified_project? project.id, user.id
    end

    can :add_membership, Project, &project_manager_of_specified_project_checker
    can :remove_membership, Project, &project_manager_of_specified_project_checker


    project_manager_of_common_project_checker = -> (target_user) do
      # Find common projects between the two
      target_user_projects = target_user.project_ids
      user_projects = user.project_ids
      common_projects = target_user_projects & user_projects

      # Check to see if the user taking the action is a project manager of _any_
      # common project they are both in
      common_projects.any? do |p_id|
        ProjectManagersService.is_user_a_manager_of_specified_project? p_id, user.id
      end
    end

    can :onboard_github, User, &project_manager_of_common_project_checker
    can :offboard_github, User, &project_manager_of_common_project_checker


    can :global, Announcement
    can :show, Announcement


    can do |action, subject_class, subject|
      if action == :search && subject_class == User
        user.admin? || ProjectManagersService.is_user_a_manager_of_any_project?(user.id)
      end
    end

  end

end
