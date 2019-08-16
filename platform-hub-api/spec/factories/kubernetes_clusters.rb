FactoryBot.define do

  factory :kubernetes_cluster do
    sequence :name do |n|
      "dev_#{n}"
    end
    description { 'Dev cluster' }

    s3_region { 'eu-west-2' }
    s3_bucket_name { 'some-bucket' }
    s3_access_key_id { ENCRYPTOR.encrypt('s3_access_key_id') }
    s3_secret_access_key { ENCRYPTOR.encrypt('s3_secret_access_key') }
    s3_object_key { 's3/object/key.csv' }

    transient do
      allocate_to { nil }
    end

    after(:create) do |cluster, evaluator|
      unless evaluator.allocate_to.blank?
        Array(evaluator.allocate_to).each do |ar|
          raise ArgumentError, '[factory create error] allocate_to must be a Project' unless ar.is_a?(Project)
          unless Allocation.exists?(allocatable: cluster, allocation_receivable: ar)
            create :allocation, allocatable: cluster, allocation_receivable: ar
          end
        end
      end
    end
  end

end
