transport_options = if ENV.has_key?('INTERNAL_SERVICES_CA_FILE')
  { ssl: { ca_file: ENV['INTERNAL_SERVICES_CA_FILE'] } }
else
  {}
end

ELASTICSEARCH_CLIENT = Elasticsearch::Client.new(
  url: ENV.fetch('PHUB_ELASTICSEARCH_URL'),
  transport_options: transport_options
)

if Rails.env.development?
  logger           = ActiveSupport::Logger.new(STDERR)
  logger.level     = Logger::INFO
  logger.formatter = proc { |s, d, p, m| "\e[2m#{m}\n\e[0m" }
  ELASTICSEARCH_CLIENT.transport.logger = logger
end
