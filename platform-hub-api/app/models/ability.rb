class Ability
  include CanCan::Ability

  def initialize(user)

    # IMPORTANT: to understand the caveats when using blocks to specify
    # abilities, see: https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities-with-Blocks


    # Hub admin role
    # Note: this will take precedence over everything below!
    can :manage, :all if user.admin?


    #  Special hub limited_admin role
    if user.limited_admin?
      can :read, CostsReport
    end


    # Projects

    can :add_membership, Project do |project|
      can_administer_project project, user
    end
    can :remove_membership, Project do |project|
      can_administer_project project, user
    end
    can :set_role, Project do |project|
      can_administer_project project, user
    end
    can :unset_role, Project do |project|
      can_administer_project project, user
    end
    can :administer_projects, Project do |project|
      can_administer_project project, user
    end
    can :read_resources_in_project, Project do |project|
      can_participate_in_project project, user
    end
    can :bills, Project do |project|
      can_participate_in_project project, user
    end

    # Tokens in projects
    can :administer_user_tokens, KubernetesToken do |token|
      can_administer_user_token token, user
    end
    can :create_user_tokens, Project do |project|
      (can_administer_project project, user)  || (can_create_user_token project, user)
    end


    # Services in projects

    can :read_services_in_project, Project do |project|
      can_participate_in_project project, user
    end
    can :administer_services_in_project, Project do |project|
      can_administer_project project, user
    end
    can :read_resources_in_services_in_project, Project do |project|
      can_participate_in_project project, user
    end
    can :administer_resources_in_services_in_project, Project do |project|
      can_administer_project project, user
    end


    # Docker repos in projects

    can :read_docker_repos_in_project, Project do |project|
      can_participate_in_project project, user
    end
    can :administer_docker_repos_in_project, Project do |project|
      can_administer_project project, user
    end


    # Users

    can :identities, User do |target_user|
      target_user == user
    end

    can :onboard_github, User do |target_user|
      can_onboard_or_offboard_github user, target_user
    end
    can :offboard_github, User do |target_user|
      can_onboard_or_offboard_github user, target_user
    end


    # Announcements

    can :global, Announcement
    can :show, Announcement


    can do |action, subject_class, subject|
      if action == :search && subject_class == User
        ProjectMembershipsService.is_user_an_admin_of_any_project?(user.id)
      end
    end

  end

  private

  def can_administer_project project, user
    ProjectMembershipsService.is_user_an_admin_of_project?(
      project.id,
      user.id
    )
  end

  def can_participate_in_project project, user
    ProjectMembershipsService.is_user_a_member_of_project?(
      project.id,
      user.id
    )
  end

  def can_onboard_or_offboard_github user, target_user
    (user == target_user) ||
    ProjectMembershipsService.is_user_an_admin_of_a_common_project?(
      user,
      target_user
    )
  end

  def can_create_user_token project, user
      Kubernetes::KubernetesTokensService.is_user_a_member_of_project?(
        project.id,
        user.id
      )
  end

  def can_administer_user_token token, user
    ProjectMembershipsService.is_user_an_admin_of_project?(
      token.project_id,
      user.id
    )||
    (user.id == token.tokenable.user.id) &&
    Kubernetes::KubernetesTokensService.is_user_a_holder_of_token?(
      token.tokenable,
      token.cluster_id,
      token.project_id
    )
  end

end
