module Docs
  class DocProcessor

    include Agents::GitHubAgentInstance
    include Agents::GitLabAgentInstance

    def fetch_and_process docs_source_entry
      case
      when docs_source_entry.docs_source.github_repo?
        git_hub_repo_doc_processor.fetch_and_process docs_source_entry
      when docs_source_entry.docs_source.hosted_gitlab_repo?
        hosted_git_lab_repo_doc_processor.fetch_and_process docs_source_entry
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

    def hosted_git_lab_repo_doc_processor
      @hosted_git_lab_repo_doc_processor ||= HostedGitLabRepoDocProcessor.new(
        git_lab_agent: git_lab_agent_service
      )
    end

  end
end
