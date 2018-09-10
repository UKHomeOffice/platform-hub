module Docs
  class DocsSyncService

    include Agents::GitHubAgentInstance

    def initialize help_search_service:
      @help_search_service = help_search_service
    end

    def sync_all
      DocsSource.all.each do |docs_source|
        case
        when docs_source.github_repo?
          git_hub_repo_docs_sync_service.sync docs_source
        when docs_source.gitlab_repo?
          # NOOP for now
        else
          raise "Kind '#{docs_source.kind}' (for DocsSource ID '#{docs_source.id}') not currently supported for docs syncing"
        end
      end
    end

    private

    def git_hub_repo_docs_sync_service
      @git_hub_repo_docs_sync_service ||= GitHubRepoDocsSyncService.new(
        git_hub_agent: git_hub_agent_service,
        help_search_service: @help_search_service
      )
    end

  end
end
