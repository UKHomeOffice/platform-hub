module ApiJsonErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found_error
    rescue_from ActiveRecord::ReadOnlyRecord, with: :readonly_error
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

  def render_model_errors errors
    render_error errors.full_messages.to_sentence, :unprocessable_entity
  end

  def not_found_error
    render_error 'Resource not found', :not_found
  end

  def readonly_error
    render_error 'Resource is readonly', :unprocessable_entity
  end

end
