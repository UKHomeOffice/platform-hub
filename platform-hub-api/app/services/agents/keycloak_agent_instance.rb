module Agents
  module KeycloakAgentInstance

    protected

    def keycloak_agent_service
      @keycloak_agent_service ||= Agents::KeycloakAgentService.new(
        base_url: Rails.application.secrets.agent_keycload_base_url,
        realm: Rails.application.secrets.agent_keycload_realm,
        client_id: Rails.application.secrets.agent_keycloak_client_id,
        client_secret: Rails.application.secrets.agent_keycloak_client_secret,
        username: Rails.application.secrets.agent_keycload_username,
        password: Rails.application.secrets.agent_keycload_password
      )
    end
  end
end
