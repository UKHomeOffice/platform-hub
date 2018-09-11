module Docs
  class GitHubRepoDocsSyncService < DocsSourceSyncBase

    BASE_HREF = "https://github.com".freeze

    def initialize git_hub_agent:, help_search_service:
      @git_hub_agent = git_hub_agent
      super(help_search_service)
    end

    protected

    def supported? docs_source
      docs_source.github_repo?
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

      data = @git_hub_agent.repo_tree repo, branch

      if data[:truncated] == true
        Rails.logger.warn "GitHub tree listing for repo '#{repo}' (branch: #{branch} was truncated - some docs may be missing)"
      end

      data
    end

    def select_doc_items tree_data
      Array(tree_data[:tree]).select do |i|
        is_blob = i[:type] == 'blob'

        is_blob && is_doc?(i[:path])
      end
    end

    def entry_data_for item, config
      path = item[:path]
      url = "#{BASE_HREF}/#{config[:repo]}/blob/#{config[:branch]}/#{path}"

      {
        content_id: path,
        content_url: url,
        metadata: {
          'api_url' => item[:url],
          'sha' => item[:sha],
          'size' => item[:size]
        }
      }
    end

    def additional_metadata_from tree_data
      {
        'sha' => tree_data[:sha],
        'truncated' => tree_data[:truncated]
      }
    end

  end
end
