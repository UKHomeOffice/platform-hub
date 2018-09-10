module Docs
  class DocsSourceEntryProcessorBase

    def fetch_and_process docs_source_entry
      return false if !supported?(docs_source_entry)

      content = fetch_content docs_source_entry

      content = content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

      # IMPORTANT: currently, we only support (and thus assume) Markdown docs

      doc = CommonMarker.render_doc content, :VALIDATE_UTF8

      headings = sanitize_all(get_headings_from(doc))

      content = sanitize_all(doc.to_html)

      {
        title: headings.first || '<NO TITLE>',
        content: content,
        headings: headings
      }
    rescue => ex
      error_serialised = "[#{ex.class.name}] #{ex.message} - #{ex.backtrace}"

      Rails.logger.error "#{self.class.name} fetch and process failed for docs source entry '#{docs_source_entry.id}' - error: #{error_serialised}"

      {}
    end

    protected

    def sanitize_all strings
      Array(strings).map do |s|
        sanitizer.sanitize s
      end
    end

    def sanitizer
      @sanitizer ||= Rails::Html::FullSanitizer.new
    end

    def get_headings_from doc
      headings = []

      doc.walk do |node|
        headings << get_string_content_from(node) if node.type == :header
      end

      headings
    end

    def get_string_content_from header_node
      s = ''

      header_node.each do |subnode|
        s += if subnode.type == :text
          subnode.string_content
        else
          get_string_content_from subnode
        end
      end

      s
    end

    # The following methods MUST be implemented in classes that inherit this base

    def supported? docs_source_entry
      fail NotImplementedError
    end

    def fetch_content docs_source_entry
      fail NotImplementedError
    end

  end
end
