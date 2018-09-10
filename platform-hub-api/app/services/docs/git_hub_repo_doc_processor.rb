module Docs
  class GitHubRepoDocProcessor < DocsSourceEntryProcessorBase

    def initialize git_hub_agent:
      @git_hub_agent = git_hub_agent
    end

    protected

    def supported? docs_source_entry
      docs_source_entry.docs_source.github_repo?
    end

    def fetch_content docs_source_entry
      repo = docs_source_entry.docs_source.config['repo']
      blob_sha = docs_source_entry.metadata['sha']

      @git_hub_agent.blob_content repo, blob_sha
    end

  end
end
