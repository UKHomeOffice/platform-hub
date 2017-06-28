module Kubernetes
  module TokenSyncService
    extend self

    module Errors
      class TokensFileBlank < StandardError; end
    end

    def sync_tokens(opts = {})
      raise 'Missing `cluster` in options.' if opts[:cluster].blank?

      begin 
        body = Kubernetes::TokenFileService.generate(opts[:cluster])
        raise Errors::TokensFileBlank, 'Tokens file empty!' if body.blank?

        config = get_s3_config(opts[:cluster])

        s3_bucket(config).put_object(
          key: opts[:object_key] || config[:object_key],
          body: body,
          server_side_encryption: opts[:sse] || 'aws:kms',
          acl: opts[:acl] || 'private',
        )
      rescue => e
        Rails.logger.error("Kubernetes Tokens sync to S3 failed! #{e.message}")
        raise
      end
    end

    private 

    def s3_bucket(config)
      client = Aws::S3::Client.new(config[:credentials])
      Aws::S3::Resource.new(client: client).bucket(config[:bucket_name])
    end

    def get_s3_config(cluster)
      config = get_cluster_data(cluster)['config']['s3_bucket']
      raise 'Cluster S3 configuration not found!' if config.blank?
      {
        :bucket_name => config['bucket_name'],
        :object_key => config['object_key'],
        :credentials => {
          region: config['region'],
          access_key_id: ENCRYPTOR.decrypt(config['access_key_id']),
          secret_access_key: ENCRYPTOR.decrypt(config['secret_access_key']),
        }
      }
    end

    def get_cluster_data(cluster)
      HashRecord.kubernetes.find_by!(id: 'clusters').data.find {|c| c['id'] == cluster} || {}
    end

  end
end
