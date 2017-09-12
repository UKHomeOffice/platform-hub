module Kubernetes
  module ClusterService
    extend self

    # Clusters data is stored in HashRecord as:
    # data: [
    #   {
    #     "id" => "production",
    #     "description" => "Production cluster",
    #     "config" => {
    #       "s3_bucket" => {
    #         "region" => "s3_region",
    #         "bucket_name" => "s3_bucket_name",
    #         "access_key_id" => "encrypted_s3_access_key_id",
    #         "secret_access_key" => "encrypted_s3_secret_access_key",
    #         "object_key" => "path/to/tokens.yaml",
    #       }
    #     }
    #   }
    #   ...
    # ]
    # Note: AWS S3 bucket credentials are encrypted!
    #
    # There are respective rake tasks to facilitate kubernetes clusters configuration management

    def create_or_update(opts = {})
      configuration = clusters_config_hash_record

      cluster_config_index = configuration.data.find_index {|c| c['id'] == opts[:id] }

      new_config = {
        id: opts[:id],
        description: opts[:description],
        config: {
          s3_bucket: {
            region: opts[:s3_region],
            bucket_name: opts[:s3_bucket_name],
            access_key_id: ENCRYPTOR.encrypt(opts[:s3_access_key_id]),
            secret_access_key: ENCRYPTOR.encrypt(opts[:s3_secret_access_key]),
            object_key: opts[:object_key],
          }
        }
      }

      configuration.with_lock do
        if cluster_config_index.blank?
          configuration.data << new_config
        else
          new_data = configuration.data.dup
          new_data[cluster_config_index] = new_config
          configuration.data = new_data
        end

        configuration.save!
        "Created/updated `#{opts[:id]}` kubernetes cluster configuration"
      end
    end

    def delete(cluster_id)
      configuration = clusters_config_hash_record
      configuration.with_lock do
        configuration.data.reject! do |c|
          c['id'] == cluster_id.to_s
        end
        configuration.save!
        "Deleted `#{cluster_id}` kubernetes cluster configuration"
      end
    end

    def clusters_config_hash_record
      HashRecord.kubernetes.find_or_create_by!(id: 'clusters') do |r|
        r.data = []
      end
    end

    def list
      clusters_config_hash_record.data
    end

    def get id
      list.find {|c| c['id'] == id} || {}
    end

  end
end
