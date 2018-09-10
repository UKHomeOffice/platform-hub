module Docs
  class HostedGitLabRepoDocsSyncService < DocsSourceSyncBase

    def initialize git_lab_agent:, help_search_service:
      @git_lab_agent = git_lab_agent
      super(help_search_service)
    end

    protected

    def supported? docs_source
      docs_source.hosted_gitlab_repo?
    end

    def config_for_tree_data_fetch docs_source
      {
        repo: docs_source.config['repo'],
        branch: docs_source.config['branch'] || 'master'
      }
    end

    def fetch_tree_data config
      repo = config[:repo]
      branch = config[:branch]

      @git_lab_agent.repo_tree repo, branch
    end

    def select_doc_items tree_data
      tree_data.select do |i|
        is_blob = i.type == 'blob'

        is_blob && is_doc?(i.path)
      end
    end

    def entry_data_for item, config
      path = item.path
      url = "#{@git_lab_agent.base_url}/#{config[:repo]}/blob/#{config[:branch]}/#{path}"

      {
        content_id: path,
        content_url: url,
        metadata: {
          'sha' => item.id
        }
      }
    end

    def additional_metadata_from tree_data
      { }
    end

  end
end
