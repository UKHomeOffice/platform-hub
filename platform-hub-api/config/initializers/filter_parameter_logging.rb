# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :password,
  :token,
  :access_token,
  :auth_token,
  :secret_key_base,
  :secret_token,
  :secret,
  :session,
  :cookie,
  :csrf,
  :salt,
  :s3_bucket_name,
  :s3_access_key_id,
  :s3_secret_access_key,
  :object_key,
  :ca_cert_encoded
]
