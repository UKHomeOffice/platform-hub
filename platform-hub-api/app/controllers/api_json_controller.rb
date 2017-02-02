class ApiJsonController < AuthorizedController
  include ApiJsonErrorHandler

  before_action :only_accept_json

  protected

  def only_accept_json
    unless request.accepts.any? { |m| m.json? || m.to_s == '*/*' }
      render_error 'Only JSON is supported as an ACCEPT media type', :not_acceptable
    end
  end
end
