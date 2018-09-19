module Docs
  class DocsSyncService

    include Agents::GitHubAgentInstance
    include Agents::GitLabAgentInstance

    def initialize help_search_service:
      @help_search_service = help_search_service
    end

    def sync_all
      return false unless allow_sync?

      DocsSource.all.each(&method(:sync))
    end

    def sync docs_source
      return false unless allow_sync?

      case
      when docs_source.github_repo?
        git_hub_repo_docs_sync_service.sync docs_source
      when docs_source.hosted_gitlab_repo?
        hosted_git_lab_repo_docs_sync_service.sync docs_source
      else
        raise "Kind '#{docs_source.kind}' (for DocsSource ID '#{docs_source.id}') not currently supported for docs syncing"
      end
    end

    private

    def allow_sync?
      FeatureFlagService.is_enabled?(:docs_sync)
    end

    def git_hub_repo_docs_sync_service
      @git_hub_repo_docs_sync_service ||= GitHubRepoDocsSyncService.new(
        git_hub_agent: git_hub_agent_service,
        help_search_service: @help_search_service
      )
    end

    def hosted_git_lab_repo_docs_sync_service
      @hosted_git_lab_repo_docs_sync_service ||= HostedGitLabRepoDocsSyncService.new(
        git_lab_agent: git_lab_agent_service,
        help_search_service: @help_search_service
      )
    end

  end
end
