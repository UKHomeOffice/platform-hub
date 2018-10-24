should_notify_exceptions = ENV.include?('NOTIFY_EXCEPTIONS') && ENV['NOTIFY_EXCEPTIONS'] != 'false'

if should_notify_exceptions
  Rails.application.config.middleware.use ExceptionNotification::Rack,
    slack: {
      webhook_url: Rails.application.secrets.slack_webhook,
      channel: ENV.fetch('NOTIFY_EXCEPTIONS_SLACK_CHANNEL'),
      additional_parameters: {
        icon_emoji: ':bangbang:',
      },
    }
end
