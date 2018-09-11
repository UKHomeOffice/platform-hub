module Agents
  module GitLabAgentInstance

    protected

    def git_lab_agent_service
      @git_lab_agent_service ||= Agents::GitLabAgentService.new(
        base_url: Rails.application.secrets.agent_gitlab_base_url,
        token: Rails.application.secrets.agent_gitlab_token
      )
    end
  end
end
