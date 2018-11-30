Shoryuken.sqs_client = Aws::SQS::Client.new(
  region: Rails.application.secrets.sqs_region,
  access_key_id: Rails.application.secrets.sqs_access_key_id,
  secret_access_key: Rails.application.secrets.sqs_secret_access_key
)

# Enable Long Polling
# Ref: https://github.com/phstc/shoryuken/wiki/Long-Polling
#
# Also, process one by one
# Ref: https://github.com/phstc/shoryuken/wiki/FIFO-Queues#process-one-by-one
Shoryuken.sqs_client_receive_message_opts = {
  wait_time_seconds: 20,
  max_number_of_messages: 1,
}
