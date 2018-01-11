module UserActivationService
  extend Agents::KeycloakAgentInstance
  extend Agents::GitHubAgentInstance
  extend self

  def activate! user
    keycloak_agent_service.activate_user(user)

    if user.github_identity
      begin
        git_hub_agent_service.onboard_user user
      rescue => e
        logger.error "Failed to onboard to Github whilst activating user. Still continuing with activation. Exception type: #{e.class.name}. Message: #{e.message}"
      end
    end

    user.activate!
  end

  def deactivate! user
    keycloak_agent_service.deactivate_user(user)

    if user.github_identity
      begin
        git_hub_agent_service.offboard_user user
      rescue => e
        logger.error "Failed to offboard from Github whilst deactivating user. Still continuing with deactivation. Exception type: #{e.class.name}. Message: #{e.message}"
      end
    end

    user.deactivate!
  end

end
