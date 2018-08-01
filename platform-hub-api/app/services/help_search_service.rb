class HelpSearchService

  module Types
    SUPPORT_REQUEST = 'support-request'.freeze
  end

  module Errors
    class SearchUnavailable < StandardError; end
  end

  def self.instance
    @instance ||= HelpSearchService.new(
      es_client: ELASTICSEARCH_CLIENT,
      index_name: "phub_#{Rails.env}_help_items"
    )
  end

  attr_reader :repository

  def initialize es_client:, index_name:
    @repository = initialize_repository(
      es_client: es_client,
      index_name: index_name
    )
  end

  def reindex_all force: false
    if force
      @repository.delete_index! if @repository.index_exists?
      @repository.create_index!
    else
      ensure_available
    end

    SupportRequestTemplate.all.each(&method(:index_item))
  end

  def index_item item
    ensure_available

    case item
    when SupportRequestTemplate
      @repository.save(
        id: id_for(item),
        type: Types::SUPPORT_REQUEST,
        hub_id: item.friendly_id,
        title: item.title,
        content: item.description + "\n\n" + (item.form_spec['help_text'] || '')
      )
    else
      raise "Item of class '#{item.class.name}' not supported for indexing by the HelpSearchService"
    end
  end

  def delete_item item
    ensure_available

    case item
    when SupportRequestTemplate
      @repository.delete(id_for(item))
    else
      raise "Item of class '#{item.class.name}' not supported for deletion by the HelpSearchService"
    end
  end

  def search query
    ensure_available

    results = @repository.search(
      query: {
        multi_match: {
          query: query,
          fields: ['title^10', 'content']
        }
      },
      highlight: {
        fields: {
          title: { number_of_fragments: 0 },
          content: { number_of_fragments: 3 }
        }
      }
    )

    Array(results.response.hits.hits).map do |h|
      {
        'item' => h._source.to_hash,
        'highlights' => h.highlight.to_hash
      }
    end
  end

  private

  def id_for item
    "#{item.class.name}:#{item.id}"
  end

  def initialize_repository es_client:, index_name:
    Elasticsearch::Persistence::Repository.new do

      client es_client

      index index_name

      type :item

      settings number_of_shards: 1, number_of_replicas: 0 do
        mapping do
          indexes :type, type: :keyword
          indexes :hub_id, type: :keyword
          indexes :title
          indexes :content, analyzer: 'snowball'
        end
      end

    end
  end

  def ensure_available
    raise Errors::SearchUnavailable unless @repository.index_exists?
  end

end
