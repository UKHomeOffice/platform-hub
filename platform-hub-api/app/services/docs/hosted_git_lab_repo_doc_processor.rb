module Docs
  class HostedGitLabRepoDocProcessor < DocsSourceEntryProcessorBase

    def initialize git_lab_agent:
      @git_lab_agent = git_lab_agent
    end

    protected

    def supported? docs_source_entry
      docs_source_entry.docs_source.hosted_gitlab_repo?
    end

    def fetch_content docs_source_entry
      repo = docs_source_entry.docs_source.config['repo']
      branch = docs_source_entry.docs_source.config['branch'] || 'master'

      @git_lab_agent.file_content(
        repo,
        docs_source_entry.content_id,
        branch
      )
    end

  end
end
