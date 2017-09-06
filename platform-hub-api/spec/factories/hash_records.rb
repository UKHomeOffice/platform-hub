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
                bucket_name: 'dev-bucket-name',
                access_key_id: ENCRYPTOR.encrypt('access-key-id'),
                secret_access_key: ENCRYPTOR.encrypt('secret-access-key'),
                object_key: 'path/to/tokens.csv',
              }
            }
          },
          {
            id: 'production',
            description: 'Production cluster',
            config: {
              s3_bucket: {
                region: 'eu-west-1',
                bucket_name: 'prod-bucket-name',
                access_key_id: ENCRYPTOR.encrypt('access-key-id'),
                secret_access_key: ENCRYPTOR.encrypt('secret-access-key'),
                object_key: 'path/to/tokens.csv',
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

    factory :kubernetes_robot_tokens_hash_record do
      scope 'kubernetes'
      data []

      transient do
        cluster 'test'
      end

      after :build do |hr, evaluator|
        hr.id = "#{evaluator.cluster}-static-robot-tokens"
      end
    end

    factory :feature_flags_hash_record do
      scope 'general'
      id 'feature_flags'

      transient do
        flags do
          {
            'some_flag': false,
            'other_flag': true
          }
        end
      end

      after :build do |hr, evaluator|
        hr.data = evaluator.flags
      end
    end

  end
end
