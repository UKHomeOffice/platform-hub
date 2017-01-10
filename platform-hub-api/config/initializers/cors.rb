# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# NOTE: we're expecting the proxy that sits in the front of the API server to take care of CORS headers
# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins 'localhost:3000'
#
#     resource '*',
#       headers: :any,
#       methods: [:get, :post, :put, :patch, :delete, :options, :head]
#   end
# end
