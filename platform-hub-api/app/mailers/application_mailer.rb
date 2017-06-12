class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.config.email_from_address
  layout 'mailer'
end
