module HelpSearchStatsService

  KEY = 'help_search_stats'

  LAST_RESULT_SIZES_TO_KEEP = 3

  def self.count_query(query, results_size)
    return if query.blank?

    normalised_query = query.strip.downcase

    record = get_hash_record

    record.with_lock do
      queries = record.data['queries']

      data = if queries.has_key? normalised_query
        queries[normalised_query]
      else
        queries[normalised_query] = {
          'count' => 0,
          'last_result_sizes' => []
        }
      end

      data['count'] += 1
      data['last_result_sizes'] << results_size
      data['last_result_sizes'] = data['last_result_sizes'].last(LAST_RESULT_SIZES_TO_KEEP)

      record.save!
    end
  rescue => ex
    Rails.logger.error "Failed to record help search stats for query: #{query} - error: #{ex.message}"
  end

  def self.query_stats
    stats = get_hash_record
      .data['queries']
      .each_with_object([]) do |(k,v), acc|
        acc << {
          query: k,
          count: v['count'],
          last_result_sizes: v['last_result_sizes']
        }
      end

    stats.sort do |a, b|
      c = (b[:count] <=> a[:count])
      c.zero? ? (a[:query] <=> b[:query]) : c
    end
  end

  private_class_method def self.get_hash_record
    HashRecord.find_or_create_by!(id: KEY, scope: 'general') do |r|
      r.data = {
        'queries' => {}
      }
    end
  end


end
