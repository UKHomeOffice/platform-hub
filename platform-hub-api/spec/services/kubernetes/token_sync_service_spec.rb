require 'rails_helper'

describe Kubernetes::TokenSyncService, type: :service do

  describe '.sync_tokens' do
    let(:cluster_name) { 'development' }
    let(:cluster) { create(:kubernetes_cluster, name: cluster_name) }
    let(:s3_bucket) { double(:s3_bucket) }
    let(:tokens_file_content) { 'tokens file contenet in csv format' }

    before do
      allow(subject).to receive(:s3_bucket).with(cluster) { s3_bucket }
    end

    context 'when generated tokens file is blank' do
      before do
        expect(Kubernetes::TokenFileService).to receive(:generate).with(cluster_name) { '' }
      end

      it 'raises an exception and does not perform sync' do
        expect { subject.sync_tokens(cluster_name) }
          .to raise_error(Kubernetes::TokenSyncService::Errors::TokensFileBlank, 'Tokens file empty!')
      end
    end

    context 'tokens file s3 object key not passed as option' do
      before do
        expect(Kubernetes::TokenFileService).to receive(:generate).with(cluster_name) { tokens_file_content }
      end

      it 'uploads tokens file to S3 using s3_object_key from cluster configuration' do
        expect(s3_bucket).to receive(:put_object).with(
          key: cluster.s3_object_key,
          body: tokens_file_content,
          server_side_encryption: 'aws:kms',
          acl: 'private',
        )

        subject.sync_tokens(cluster_name)
      end
    end

    context 'token file s3 object key passed as option' do
      let(:custom_object_key) { 'some/path/tokens.csv' }

      before do
        expect(Kubernetes::TokenFileService).to receive(:generate).with(cluster_name) { tokens_file_content }
      end

      it 'uploads tokens file to S3 using s3_object_key passed in options' do
        expect(s3_bucket).to receive(:put_object).with(
          key: custom_object_key,
          body: tokens_file_content,
          server_side_encryption: 'aws:kms',
          acl: 'private',
        )

        subject.sync_tokens(cluster_name, s3_object_key: custom_object_key)
      end
    end
  end

end
