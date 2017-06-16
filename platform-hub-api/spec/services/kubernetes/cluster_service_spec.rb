require 'rails_helper'

describe Kubernetes::ClusterService, type: :service do

  let(:cluster_id) { 'cluster-id' }
  let(:cluster_desc) { 'cluster-desc' }
  let(:s3_region) { 's3-region' }
  let(:s3_bucket_name) { 's3-bucket-name' }
  let(:s3_access_key_id) { 's3-access-key' }
  let(:s3_secret_access_key) { 's3-secret-key' }
  let(:object_key) { 'object-key' }

  let(:new_cluster_config) do
    {
      id: cluster_id,
      description: cluster_desc,
      s3_region: s3_region,
      s3_bucket_name: s3_bucket_name,
      s3_access_key_id: s3_access_key_id,
      s3_secret_access_key: s3_secret_access_key,
      object_key: object_key,
    }
  end


  before do
    create(:hash_record,
      id: 'clusters',
      scope: 'kubernetes',
      data: []
    )

    @clusters_config = HashRecord.kubernetes.find_by!(id: "clusters")
  end

  describe '.create_or_update' do
    let(:new_groups) { ['g1','g2'] }

    context 'given cluster configuration does not exist yet' do
      it 'creates a new cluster configuration' do
        expect {
          subject.create_or_update(new_cluster_config)
        }.to change { @clusters_config.reload.data.size }.by(1)

        new_cluster = @clusters_config.data.last
        
        expect(new_cluster['id']).to eq cluster_id
        expect(new_cluster['description']).to eq cluster_desc

        s3_bucket = new_cluster['config']['s3_bucket']

        expect(s3_bucket['region']).to eq s3_region
        expect(s3_bucket['bucket_name']).to eq s3_bucket_name
        expect(ENCRYPTOR.decrypt(s3_bucket['access_key_id'])).to eq s3_access_key_id
        expect(ENCRYPTOR.decrypt(s3_bucket['secret_access_key'])).to eq s3_secret_access_key
        expect(s3_bucket['object_key']).to eq object_key
      end
    end

    context 'cluster configuration already exist' do
      let(:new_description) { 'slightly different description' }
      let(:new_s3_access_key_id) { 'different-s3-access-key-id' }
      let(:new_s3_secret_access_key) { 'different-s3-secret-access-key' }

      before do
        subject.create_or_update(new_cluster_config)

        new_cluster_config[:description] = new_description
        new_cluster_config[:s3_access_key_id] = new_s3_access_key_id
        new_cluster_config[:s3_secret_access_key] = new_s3_secret_access_key
      end

      it 'updates existing robot account record' do
        expect {
          subject.create_or_update(new_cluster_config)
        }.to change { @clusters_config.reload.data.size }.by(0)

        existing_cluster = @clusters_config.data.first

        expect(existing_cluster['id']).to eq cluster_id
        expect(existing_cluster['description']).to eq new_description

        s3_bucket = existing_cluster['config']['s3_bucket']

        expect(ENCRYPTOR.decrypt(s3_bucket['access_key_id'])).to eq new_s3_access_key_id
        expect(ENCRYPTOR.decrypt(s3_bucket['secret_access_key'])).to eq new_s3_secret_access_key
      end
    end
  end

  describe '.delete' do
    before do
      subject.create_or_update(new_cluster_config)
    end

    it 'removes cluster configuration from the list' do
      expect {
        subject.delete(cluster_id)
      }.to change { @clusters_config.reload.data.size }.by(-1)

      expect(@clusters_config.data.size).to eq 0
    end
  end

end
