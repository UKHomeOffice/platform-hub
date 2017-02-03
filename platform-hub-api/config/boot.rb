ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.


# -----
# Based on: http://stackoverflow.com/a/33852354/238287
# See README for why we force bind to 0.0.0.0 in development mode

require 'rails/commands/server'

if Rails.env.development?
  module RailsServerDefaultOptions
    def default_options
      super.merge!(Host: '0.0.0.0')
    end
  end
  Rails::Server.prepend(RailsServerDefaultOptions)
end

#-----
