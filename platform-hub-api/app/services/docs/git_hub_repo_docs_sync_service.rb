module Docs
  class GitHubRepoDocsSyncService

    MARKDOWN_FILE_EXTS = ['.markdown', '.md', '.mdown', '.mkdn'].freeze

    BASE_HREF = "https://github.com".freeze

    def initialize git_hub_agent:, help_search_service:
      @git_hub_agent = git_hub_agent
      @help_search_service = help_search_service
    end

    def sync docs_source
      return false if !docs_source.github_repo? || docs_source.is_fetching

      start = Time.current

      docs_source.update!(
        is_fetching: true,
        last_fetch_status: nil,
        last_fetch_started_at: start,
        last_fetch_error: nil
      )

      repo = docs_source.config['repo']
      branch = docs_source.config['branch'] || 'master'

      data = @git_hub_agent.repo_tree repo, branch

      if data[:truncated] == true
        Rails.logger.warn "GitHub tree listing for repo '#{repo}' (branch: #{branch} was truncated - some docs may be missing)"
      end

      markdown_items = select_markdown_items data[:tree]

      sync_entries!(
        docs_source,
        markdown_items,
        repo,
        branch
      )

      finish = Time.current

      docs_source.update!(
        is_fetching: false,
        last_fetch_status: :successful,
        last_successful_fetch_started_at: start,
        last_successful_fetch_metadata: {
          'sha' => data[:sha],
          'truncated' => data[:truncated],
          'total_docs_found' => markdown_items.size,
          'sync_duration_secs' => (finish - start).round
        }
      )

      true
    rescue => ex
      error_serialised = "[#{ex.class.name}] #{ex.message} - #{ex.backtrace}"

      Rails.logger.error "GitHub docs sync failed for docs source #{docs_source.id} - error: #{error_serialised}"

      docs_source.update!(
        is_fetching: false,
        last_fetch_status: :failed,
        last_fetch_error: error_serialised
      )

      false
    end

    private

    def select_markdown_items items
      items.select do |i|
        is_blob = i[:type] == 'blob'

        is_markdown = MARKDOWN_FILE_EXTS.any? { |ext| i[:path].end_with?(ext) }

        is_blob && is_markdown
      end
    end

    def sync_entries! docs_source, items, repo, branch
      current_entries_by_path = docs_source
        .entries
        .each_with_object({}) do |e, acc|
          acc[e.content_id] = e
        end

      processed = []

      items.each do |i|
        path = i[:path]

        metadata = {
          'api_url': i[:url],
          'sha' => i[:sha],
          'size' => i[:size]
        }

        content_url = "#{BASE_HREF}/#{repo}/blob/#{branch}/#{path}"

        entry = if current_entries_by_path.has_key? path
          # Update existing
          current_entries_by_path[path].tap do |e|
            e.update!(
              content_url: content_url,
              metadata: metadata
            )
          end
        else
          # Create new
          docs_source.entries.create!(
            content_id: path,
            content_url: content_url,
            metadata: metadata
          )
        end

        @help_search_service.index_item entry

        processed << path
      end

      # Delete
      unprocessed = current_entries_by_path.keys - processed
      unprocessed.each do |path|
        entry = current_entries_by_path[path]
        entry.destroy!
        @help_search_service.delete_item entry
      end
    end

  end
end
