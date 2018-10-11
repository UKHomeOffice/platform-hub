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
    stats = HelpSearchStatsService
      .query_stats
      .select { |s| !s[:hidden] }
      .first(20)

    render json: stats
  end

  # POST /help/hide_search_query_stat
  def hide_search_query_stat
    authorize! :manage, :search_query_stats

    HelpSearchStatsService.mark_hidden params[:q]

    head :no_content
  end

end
