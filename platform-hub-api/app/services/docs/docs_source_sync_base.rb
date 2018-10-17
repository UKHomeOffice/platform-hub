module Docs
  class DocsSourceSyncBase

    MARKDOWN_FILE_EXTS = ['.markdown', '.md', '.mdown', '.mkdn'].freeze

    def initialize help_search_service
      @help_search_service = help_search_service
    end

    def sync docs_source
      return false if !supported?(docs_source) || docs_source.is_fetching

      start = Time.current

      docs_source.update!(
        is_fetching: true,
        last_fetch_status: nil,
        last_fetch_started_at: start,
        last_fetch_error: nil
      )

      config = config_for_tree_data_fetch docs_source

      tree_data = fetch_tree_data config

      doc_items = select_doc_items tree_data

      sync_entries!(
        docs_source,
        doc_items,
        config
      )

      finish = Time.current

      docs_source.update!(
        is_fetching: false,
        last_fetch_status: :successful,
        last_successful_fetch_started_at: start,
        last_successful_fetch_metadata: additional_metadata_from(tree_data).merge({
          'total_docs_found' => doc_items.size,
          'sync_duration_secs' => (finish - start).round
        })
      )

      true
    rescue => ex
      error_serialised = "[#{ex.class.name}] #{ex.message} - #{ex.backtrace}"

      Rails.logger.error "#{self.class.name} sync failed for docs source #{docs_source.id} - error: #{error_serialised}"

      docs_source.update!(
        is_fetching: false,
        last_fetch_status: :failed,
        last_fetch_error: error_serialised
      )

      false
    end

    def is_doc? name
      MARKDOWN_FILE_EXTS.any? { |ext| name.downcase.end_with?(ext) }
    end

    protected

    def sync_entries! docs_source, items, config
      current_entries_by_content_id = docs_source
        .entries
        .each_with_object({}) do |e, acc|
          acc[e.content_id] = e
        end

      processed = []

      items.each do |item|
        entry_data = entry_data_for item, config

        content_id = entry_data[:content_id]

        entry = if current_entries_by_content_id.has_key? content_id
          # Update existing
          current_entries_by_content_id[content_id].tap do |e|
            e.update!(
              content_url: entry_data[:content_url],
              metadata: entry_data[:metadata]
            )
          end
        else
          # Create new
          docs_source.entries.create!(
            content_id: content_id,
            content_url: entry_data[:content_url],
            metadata: entry_data[:metadata]
          )
        end

        @help_search_service.index_item entry

        processed << content_id
      end

      # Delete
      unprocessed = current_entries_by_content_id.keys - processed
      unprocessed.each do |content_id|
        entry = current_entries_by_content_id[content_id]
        @help_search_service.delete_item entry
        entry.destroy!
      end
    end

    # The following methods MUST be implemented in classes that inherit this base

    def supported? docs_source
      fail NotImplementedError
    end

    def config_for_tree_data_fetch docs_source
      fail NotImplementedError
    end

    def fetch_tree_data config
      fail NotImplementedError
    end

    def select_doc_items tree_data
      fail NotImplementedError
    end

    def entry_data_for item, config
      fail NotImplementedError
    end

    def additional_metadata_from tree_data
      fail NotImplementedError
    end

  end
end
