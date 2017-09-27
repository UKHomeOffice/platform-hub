require 'rails_helper'

describe Kubernetes::RobotTokenService, type: :service do

  let(:cluster) { 'foo' }

  describe '.get_by_cluster' do

    before do
      expect(Kubernetes::StaticTokenService).to receive(:get_static_tokens_hash_record)
        .with(cluster, :robot)
        .and_return(hash_record)
    end

    context 'with no existing tokens' do
      let :hash_record do
        create :kubernetes_robot_tokens_hash_record,
          cluster: cluster,
          data: []
      end

      it 'should return an empty list' do
        expect(KubernetesRobotToken).to receive(:from_data).never

        expect(Kubernetes::RobotTokenService.get_by_cluster(cluster)).to be_empty
      end
    end

    context 'with some existing tokens' do
      let :token1 do
        {
          'token' => ENCRYPTOR.encrypt('token1'),
          'user' => 'user1',
          'uid' => 'uid1',
        }
      end

      let :token2 do
        {
          'token' => ENCRYPTOR.encrypt('token2'),
          'user' => 'user2',
          'uid' => 'uid2',
        }
      end

      let :hash_record do
        create :kubernetes_robot_tokens_hash_record,
          cluster: cluster,
          data: [
            token1,
            token2
          ]
      end

      it 'return a list of tokens as expected' do
        expect(KubernetesRobotToken).to receive(:from_data).with(cluster, token1).and_call_original
        expect(KubernetesRobotToken).to receive(:from_data).with(cluster, token2).and_call_original

        tokens = Kubernetes::RobotTokenService.get_by_cluster(cluster)
        expect(tokens.length).to eq 2
        expect(tokens.map(&:name)).to eq ['user1', 'user2']
        expect(tokens.map(&:decrypted_token)).to eq ['token1', 'token2']
      end
    end

  end

  describe '.create_or_update' do
    it 'should call the Kubernetes::StaticTokenService appropriately' do
      expect(Kubernetes::StaticTokenService).to receive(:create_or_update)
        .with(cluster, :robot, 'foo', [], 'desc', 'user_id')

      Kubernetes::RobotTokenService.create_or_update(cluster, 'foo', [], 'desc', 'user_id')
    end
  end

  describe '.delete' do
    it 'should call the Kubernetes::StaticTokenService appropriately' do
      expect(Kubernetes::StaticTokenService).to receive(:delete_by_name)
        .with(cluster, :robot, 'foo')

      Kubernetes::RobotTokenService.delete(cluster, 'foo')
    end
  end

end
