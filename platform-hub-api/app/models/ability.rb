class Ability
  include CanCan::Ability

  def initialize(user)

    # IMPORTANT: to understand the caveats when using blocks to specify
    # abilities, see: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities-with-Blocks

    # This will take precedence over everything below!
    can :manage, :all if user.admin?


    # Projects

    can :add_membership, Project do |project|
      manage_project_membership project, user
    end
    can :remove_membership, Project do |project|
      manage_project_membership project, user
    end


    # Users

    can :identities, User do |target_user|
      target_user == user
    end

    can :onboard_github, User do |target_user|
      onboard_or_offboard_github user, target_user
    end
    can :offboard_github, User do |target_user|
      onboard_or_offboard_github user, target_user
    end


    # Announcements

    can :global, Announcement
    can :show, Announcement


    can do |action, subject_class, subject|
      if action == :search && subject_class == User
        ProjectManagersService.is_user_a_manager_of_any_project?(user.id)
      end
    end

  end

  private

  def manage_project_membership project, user
    ProjectManagersService.is_user_a_manager_of_project?(
      project.id,
      user.id
    )
  end

  def onboard_or_offboard_github user, target_user
    (user == target_user) ||
    ProjectManagersService.is_user_a_manager_of_a_common_project?(
      user,
      target_user
    )
  end

end
