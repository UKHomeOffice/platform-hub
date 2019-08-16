FactoryBot.define do
  factory :hash_record do
    sequence(:id) { |n| "hash_record_#{n}" }
    scope { 'general' }
    data do
      { bar: 'baz' }
    end

    factory :kubernetes_static_tokens_hash_record do
      scope { 'kubernetes' }
      id { 'development-static-user-tokens' }
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
      scope { 'kubernetes' }
      data { [] }

      transient do
        cluster { 'test' }
      end

      after :build do |hr, evaluator|
        hr.id = "#{evaluator.cluster}-static-robot-tokens"
      end
    end

    factory :feature_flags_hash_record do
      scope { 'general' }
      id { 'feature_flags' }

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
