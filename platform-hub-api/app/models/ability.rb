class Ability
  include CanCan::Ability

  def initialize(user)

    can :manage, :all if user.admin?


    project_manager_checker = -> (target_user) do
      # Find common projects between the two
      target_user_projects = target_user.project_ids
      user_projects = user.project_ids
      common_projects = target_user_projects & user_projects

      # Check to see if the user taking the action is a project manager of _any_
      # common project they are both in
      common_projects.any? do |p_id|
        ProjectMembership.exists?(project_id: p_id, user_id: user.id, role: 'manager')
      end
    end

    can :onboard_github, User, &project_manager_checker
    can :offboard_github, User, &project_manager_checker

  end

end
