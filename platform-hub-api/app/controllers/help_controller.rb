class HelpController < ApiJsonController

  skip_authorization_check only: [ :search ]

  # GET /help/search
  def search
    q = params[:q]

    if q.blank?
      head :no_content
    else
      begin
        results = HelpSearchService.instance.search(q)
        render json: results
      rescue HelpSearchService::Errors::SearchUnavailable
        logger.error 'Help search service is currently unavailable'
        service_unavailable_error 'Search is currently unavailable'
      end
    end
  end

end
