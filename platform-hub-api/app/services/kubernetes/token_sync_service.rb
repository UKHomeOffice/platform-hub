module Kubernetes
  module TokenSyncService
    extend self

    module Errors
      class TokensFileBlank < StandardError; end
    end

    def sync_tokens(cluster_name, opts = {})
      raise 'Please specify cluster name.' if cluster_name.blank?

      begin
        cluster = KubernetesCluster.friendly.find cluster_name

        body = Kubernetes::TokenFileService.generate(cluster_name)
        raise Errors::TokensFileBlank, 'Tokens file empty!' if body.blank?

        s3_bucket(cluster).put_object(
          key: opts.fetch(:s3_object_key, cluster.s3_object_key),
          body: body,
          server_side_encryption: opts.fetch(:sse, 'aws:kms'),
          acl: opts.fetch(:acl, 'private'),
        )
      rescue => e
        Rails.logger.error("Kubernetes Tokens sync to S3 failed! #{e.message}")
        raise
      end
    end

    private

    def s3_bucket(cluster)
      client = Aws::S3::Client.new({
          region: cluster.s3_region,
          access_key_id: cluster.decrypted_s3_access_key_id,
          secret_access_key: cluster.decrypted_s3_secret_access_key,
        })
      Aws::S3::Resource.new(client: client).bucket(cluster.s3_bucket_name)
    end

  end
end
