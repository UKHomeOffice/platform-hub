module Agents
  module GitHubAgentInstance

    protected

    def git_hub_agent_service
      @git_hub_agent_service ||= Agents::GitHubAgentService.new(
        token: Rails.application.secrets.agent_github_token,
        org: Rails.application.secrets.agent_github_org,
        main_team_id: Rails.application.secrets.agent_github_org_main_team_id
      )
    end
  end
end
