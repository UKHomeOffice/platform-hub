class ApiJsonController < AuthorizedController
  include ApiJsonErrorHandler

  before_action :only_accept_json

  before_action :set_exception_notifier_data

  protected

  def only_accept_json
    unless request.accepts.any? { |m| m.json? || m.to_s == '*/*' }
      render_error 'Only JSON is supported as an ACCEPT media type', :not_acceptable
    end
  end

  def set_exception_notifier_data
    request.env['exception_notifier.exception_data'] = {
      rails_env: Rails.env,
      app_base_url: Rails.application.config.app_base_url,
      current_user_email: current_user.try(:email) || '<none>',
    }
  end
end
