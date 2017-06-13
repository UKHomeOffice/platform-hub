require 'rails_helper'

describe Kubernetes::TokenSyncService, type: :service do

  describe '.sync_tokens' do
    let(:s3_config) { double(:s3_config) }
    let(:s3_bucket) { double(:s3_bucket) }
    let(:cluster) { 'development' }
    let(:object_key) { 'some/path/tokens.yaml' }
    let(:tokens_file_content) { 'tokens file contenet' }
    let(:object_key_from_config) { 'some-object-key' }

    before do
      allow(subject).to receive(:get_s3_config).with(cluster) { s3_config }
      allow(subject).to receive(:s3_bucket).with(s3_config) { s3_bucket }
    end

    context 'when generated tokens file is blank' do
      before do
        expect(Kubernetes::TokenFileService).to receive(:generate).with(cluster) { '' }
      end

      it 'raises an exception and does not perform sync' do
        expect { subject.sync_tokens(cluster: cluster) }
          .to raise_error(Kubernetes::TokenSyncService::Errors::TokensFileBlank, 'Tokens file empty!')
      end
    end

    context 'tokens file object key not passed as option' do
      before do
        expect(Kubernetes::TokenFileService).to receive(:generate).with(cluster) { tokens_file_content }
        expect(s3_config).to receive(:[]).with(:object_key) { object_key_from_config }
      end

      it 'uploads tokens file to S3 using object_key from cluster configuration' do
        expect(s3_bucket).to receive(:put_object).with(
          key: object_key_from_config,
          body: tokens_file_content,
          server_side_encryption: 'aws:kms',
          acl: 'private',
        )

        subject.sync_tokens(cluster: cluster)
      end
    end

    context 'token file object key passed as option' do
      before do
        expect(Kubernetes::TokenFileService).to receive(:generate).with(cluster) { tokens_file_content }
      end

      it 'uploads tokens file to S3 using object_key passed in options' do
        expect(s3_bucket).to receive(:put_object).with(
          key: object_key,
          body: tokens_file_content,
          server_side_encryption: 'aws:kms',
          acl: 'private',
        )

        subject.sync_tokens(cluster: cluster, object_key: object_key)
      end
    end
  end

end
