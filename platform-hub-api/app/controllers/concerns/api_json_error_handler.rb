module ApiJsonErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
  end

  def render_error message, status
    status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
    error_doc = {
      error: {
        status: status_code,
        message: message
      }
    }
    render json: error_doc, status: status
  end

  def not_found
    render_error 'Resource not found', :not_found
  end
end
