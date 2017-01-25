# Be sure to restart your server when you modify this file.

Rails.application.config.app_base_url = ENV.fetch('APP_BASE_URL') { raise 'APP_BASE_URL missing from env' }
