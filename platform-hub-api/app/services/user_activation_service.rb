module UserActivationService
  extend Agents::KeycloakAgentInstance
  extend self

  def activate! user
    keycloak_agent_service.activate_user(user)
    user.activate!
  end

  def deactivate! user
    keycloak_agent_service.deactivate_user(user)
    user.deactivate!
  end

end
