module Docs
  class GitHubRepoDocProcessor

    def initialize git_hub_agent:
      @git_hub_agent = git_hub_agent
    end

    def fetch_and_process docs_source_entry
      docs_source = docs_source_entry.docs_source

      return false if !docs_source.github_repo?

      repo = docs_source.config['repo']
      blob_sha = docs_source_entry.metadata['sha']

      content = @git_hub_agent.blob_content repo, blob_sha

      content = content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

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

      Rails.logger.error "GitHub doc fetch and process failed for docs source entry '#{docs_source_entry.id}' - error: #{error_serialised}"

      {}
    end

    private

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
        if node.type == :header
          node.each do |subnode|
            if subnode.type == :text
              headings << subnode.string_content
            end
          end
        end
      end

      headings
    end

  end
end
