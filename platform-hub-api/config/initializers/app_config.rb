# Be sure to restart your server when you modify this file.

Rails.application.config.app_base_url = ENV.fetch('APP_BASE_URL') { raise 'APP_BASE_URL missing from env' }

Rails.application.config.email_from_address = ENV.fetch('EMAIL_FROM_ADDRESS') { raise 'EMAIL_FROM_ADDRESS missing from env' }
Rails.application.config.email_max_to_addresses = (ENV.fetch('EMAIL_MAX_TO_ADDRESSES') { raise 'EMAIL_MAX_TO_ADDRESSES missing from env' }).to_i
