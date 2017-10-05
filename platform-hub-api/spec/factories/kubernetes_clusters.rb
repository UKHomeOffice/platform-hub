FactoryGirl.define do

  factory :kubernetes_cluster do
    name { 'dev' }
    description { 'Dev cluster' }

    s3_region { 'eu-west-2' }
    s3_bucket_name { 'some-bucket' }
    s3_access_key_id { ENCRYPTOR.encrypt('s3_access_key_id') }
    s3_secret_access_key { ENCRYPTOR.encrypt('s3_secret_access_key') } 
    s3_object_key { 's3/object/key.csv' }
  end

end
