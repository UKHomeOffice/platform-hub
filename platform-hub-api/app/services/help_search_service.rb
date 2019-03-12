class HelpSearchService

  SYNONYMS = [
    'kubernetes,k8s=>kube',
    'continuous integration=>ci',
    'lets encrypt=>le',
    'kube cert manager=>kcm',
    'single signon, single sign on=>sso',
    'elasticsearch=>es',
    'logstash,kibana=>elk',
    'identity provider=>idp',
  ].freeze

  module Types
    SUPPORT_REQUEST = 'support-request'.freeze
    QA_ENTRY = 'qa-entry'.freeze
    DOC = 'doc'.freeze
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
    HelpSearchStatusService.reindex_started force

    if force
      @repository.delete_index! if @repository.index_exists?
      @repository.create_index!
    else
      ensure_available
    end

    SupportRequestTemplate.all.each(&method(:index_item))

    QaEntry.all.each(&method(:index_item))

    Docs::DocsSyncService.new(help_search_service: self).sync_all

    HelpSearchStatusService.reindex_finished
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

    when QaEntry

      @repository.save(
        id: id_for(item),
        type: Types::QA_ENTRY,
        hub_id: item.id,
        title: item.question,
        content: item.answer,
        raw_content: item.answer
      )

    when DocsSourceEntry

      processed = doc_processor.fetch_and_process(item)

      return if processed.blank?

      @repository.save(
        id: id_for(item),
        type: Types::DOC,
        hub_id: item.id,
        link: item.content_url,
        title: processed[:title],
        content: processed[:content],
        headings: processed[:headings]
      )

    else
      raise "Item of class '#{item.class.name}' not supported for indexing by the HelpSearchService"
    end
  end

  def delete_item item
    ensure_available

    case item
    when SupportRequestTemplate, QaEntry, DocsSourceEntry
      @repository.delete(id_for(item))
    else
      raise "Item of class '#{item.class.name}' not supported for deletion by the HelpSearchService"
    end
  end

  def search query
    ensure_available

    results = @repository.search(
      query: {
        function_score: {
          query: {
            multi_match: {
              query: query,
              fields: ['title^10', 'content', 'headings^7'],
              type: 'phrase',
              slop: 10
            }
          },
          functions: [
            {
              filter: { match: { type: Types::SUPPORT_REQUEST } },
              weight: 30
            },
            {
              filter: { match: { type: Types::QA_ENTRY } },
              weight: 20
            }
          ],
          score_mode: 'multiply',
          boost_mode: 'multiply'
        }
      },
      highlight: {
        fields: {
          title: {
            fragment_size: 200,
            number_of_fragments: 0,
            fragmenter: 'simple'
          },
          content: {
            fragment_size: 200,
            number_of_fragments: 3,
            fragmenter: 'simple'
          }
        }
      },
      size: 100
    )

    Array(results.response.hits.hits).map do |h|
      {
        'item' => h._source.to_hash.reject { |k,v| k == 'content' },
        'highlights' => h.highlight.respond_to?(:to_hash) ? h.highlight.to_hash : {}
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

      settings(
        number_of_shards: 1,
        number_of_replicas: 0,
        analysis: {
          filter: {
            synonym: {
              type: 'synonym',
              synonyms: SYNONYMS
            }
          },
          analyzer: {
            snowball_with_synonyms: {
              tokenizer: 'standard',
              filter: [
                'standard',
                'lowercase',
                'stop',
                'synonym',
                'snowball'
              ]
            }
          }
        }
      ) do
        mapping do
          indexes :type, type: :keyword
          indexes :hub_id, type: :keyword
          indexes :link, type: :keyword
          indexes :title, analyzer: 'snowball_with_synonyms'
          indexes :content, analyzer: 'snowball_with_synonyms'
          indexes :raw_content, index: false
          indexes :headings, analyzer: 'snowball_with_synonyms'
        end
      end

    end
  end

  def ensure_available
    raise Errors::SearchUnavailable unless @repository.index_exists?
  end

  def doc_processor
    @doc_processor ||= Docs::DocProcessor.new
  end

end
