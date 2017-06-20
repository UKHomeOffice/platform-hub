FactoryGirl.define do
  factory :hash_record do
    sequence(:id) { |n| "hash_record_#{n}" }
    scope 'general'
    data do
      { bar: 'baz' }
    end

    factory :kubernetes_clusters_hash_record do
      scope 'kubernetes'
      id 'clusters'
      data do
        [
          {
            id: 'development',
            description: 'Development cluster',
            config: {
              s3_bucket: {
                region: 'eu-west-1', 
                bucket_name: 'bucket-name',
                access_key_id: ENCRYPTOR.encrypt('access-key-id'), 
                secret_access_key: ENCRYPTOR.encrypt('secret-access-key'), 
                object_key: 'path/to/tokens.yaml',
              }
            }
          }
        ]
      end
    end

    factory :kubernetes_static_tokens_hash_record do
      scope 'kubernetes'
      id 'development-static-user-tokens'
      data do
        [
          {
            token: ENCRYPTOR.encrypt('token'),
            user: 'user', 
            uid: 'uid', 
            groups: [ 'group' ],
          }
        ]
      end
    end

  end
end
