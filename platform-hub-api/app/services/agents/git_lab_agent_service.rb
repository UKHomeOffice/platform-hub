module Agents
  class GitLabAgentService

    attr_reader :base_url

    def initialize base_url:, token:
      @base_url = base_url
      @client = Gitlab.client(
        endpoint: URI.join(base_url, 'api/v4').to_s,
        private_token: token
      )
    end

    def repo_tree repo, ref
      @client.tree(repo, ref: ref, recursive: true, per_page: 100).auto_paginate
    end

    def file_content repo, filepath, ref
      @client.file_contents(repo, filepath, ref)
    end

  end
end
