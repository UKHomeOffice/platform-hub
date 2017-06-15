SLACK_NOTIFIER ||= Slack::Notifier.new Rails.application.secrets.slack_webhook
