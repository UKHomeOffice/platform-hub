module Docs
  class DocProcessor

    include Agents::GitHubAgentInstance

    def fetch_and_process docs_source_entry
      case
      when docs_source_entry.docs_source.github_repo?
        git_hub_repo_doc_processor.fetch_and_process docs_source_entry
      when docs_source_entry.docs_source.gitlab_repo?
        # NOOP for now
      else
        raise "Kind '#{docs_source_entry.docs_source.kind}' (for DocsSourceEntry ID '#{docs_source_entry.id}') not currently supported for doc processing"
      end
    end

    private

    def git_hub_repo_doc_processor
      @git_hub_repo_doc_processor ||= GitHubRepoDocProcessor.new(
        git_hub_agent: git_hub_agent_service
      )
    end

  end
end
