Rails.application.config.action_mailer.delivery_method = :smtp
Rails.application.config.action_mailer.smtp_settings = {
  address: ENV['EMAIL_SMTP_ADDRESS'],
  port: ENV['EMAIL_SMTP_PORT'].to_i,
  user_name: ENV['EMAIL_SMTP_USERNAME'],
  password: ENV['EMAIL_SMTP_PASSWORD'],
  authentication: :plain,
  enable_starttls_auto: true
}
