class HelpController < ApiJsonController

  skip_authorization_check only: [ :search, :search_query_stats ]

  # GET /help/search
  def search
    q = params[:q]

    if q.blank?
      head :no_content
    else
      begin
        results = HelpSearchService.instance.search(q)

        HelpSearchStatsService.count_query(q, results.size) unless params[:ignore_for_stats]

        render json: results
      rescue HelpSearchService::Errors::SearchUnavailable
        logger.error 'Help search service is currently unavailable'
        service_unavailable_error 'Search is currently unavailable'
      end
    end
  end

  # GET /help/search_query_stats
  def search_query_stats
    render json: HelpSearchStatsService.query_stats.first(20)
  end

end
