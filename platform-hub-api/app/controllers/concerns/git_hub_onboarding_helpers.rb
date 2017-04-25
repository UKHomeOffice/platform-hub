module GitHubOnboardingHelpers
  extend ActiveSupport::Concern

  include AgentsInitializer

  def handle_onboard_github_request user, audit_context
    handle :onboard, user, audit_context
  end

  def handle_offboard_github_request user, audit_context
    handle :offboard, user, audit_context
  end

  private

  def handle action, user, audit_context
    begin

      success = git_hub_agent_service.send "#{action}_user", user

      if success
        AuditService.log(
          context: audit_context,
          action: "#{action}_github",
          auditable: user
        )
      else
        render_error "Failed to #{action} the user to GitHub - the GitHub API may be down", :service_unavailable
      end

      success

    rescue Agents::GitHubAgentService::Errors::IdentityMissing
      render_error 'User does not have a GitHub identity connected yet', :bad_request
      false
    rescue => e
      logger.error "Failed to call the GitHub API when attempting to #{action}. Exception type: #{e.class.name}. Message: #{e.message}"
      render_error 'Unknown error whilst calling the GitHub API', :service_unavailable
      false
    end
  end

end
