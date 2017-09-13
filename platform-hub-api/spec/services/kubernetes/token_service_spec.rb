require 'rails_helper'

describe Kubernetes::TokenService, type: :service do

  include_context 'time helpers'

  let(:identity_id) { 'some-identity-id' }
  let(:cluster) { 'development' }
  let(:token) { 'some-token' }
  let(:uid) { 'some-uid' }
  let(:groups) { ['group1', 'group2'] }
  let(:kubernetes_identity) { instance_double('Identity', provider: :kubernetes) }

  let(:kube_token) do
    {
      identity_id: kubernetes_identity.id,
      cluster: cluster,
      token: ENCRYPTOR.encrypt(token),
      uid: uid,
      groups: groups
    }
  end

  before do
    create(:hash_record,
      id: 'clusters',
      scope: 'kubernetes',
      data: [
        {id: 'production', description: 'Production cluster'}, 
        {id: 'development', description: 'Development cluster'}
      ]
    )

    allow(kubernetes_identity).to receive(:id) { identity_id }
    allow(kubernetes_identity).to receive(:data) { { tokens: [kube_token] } }
  end

  describe '.tokens_from_identity_data' do
    it 'returns list of kubernetes tokens for the given user identity data' do
      tokens = subject.tokens_from_identity_data(kubernetes_identity.data)
      expect(tokens.size).to eq 1
      expect(tokens.first.identity_id).to eq kubernetes_identity.id
      expect(tokens.first.cluster).to eq cluster
      expect(ENCRYPTOR.decrypt(tokens.first.token)).to eq token
      expect(tokens.first.uid).to eq uid
      expect(tokens.first.groups).to eq groups
    end
  end

  describe '.create_or_update_token' do
    context 'when token for given cluster does not exist' do
      before do
        allow(kubernetes_identity).to receive(:data) { { tokens: [] } }
      end

      it 'creates token and returns a <tokens, new_token> tupple' do
        tokens, new_token = subject.create_or_update_token(
          kubernetes_identity.data, 
          kubernetes_identity.id, 
          'production', 
          'g1,g2,g3'
        )
        expect(tokens.size).to eq 1
        expect(new_token.identity_id).to eq kubernetes_identity.id
        expect(new_token.cluster).to eq 'production'
        expect(new_token.token).to_not be_empty
        expect(new_token.uid).to_not be_empty
        expect(new_token.groups).to eq ['g1','g2','g3']
      end
    end

    context 'when token for given cluster already exists' do
      before do
        allow(kubernetes_identity).to receive(:data) { { tokens: [kube_token] } }
      end

      it 'updates token value (if given) and groups only and returns a <tokens, existing_token> tupple' do
        tokens, new_token = subject.create_or_update_token(
          kubernetes_identity.data, 
          kubernetes_identity.id, 
          cluster, 
          'new-group',
          'new-token'
        )
        expect(tokens.size).to eq 1
        expect(new_token.identity_id).to eq kubernetes_identity.id
        expect(new_token.cluster).to eq cluster
        expect(ENCRYPTOR.decrypt(new_token.token)).to eq 'new-token'
        expect(new_token.uid).to_not be_empty
        expect(new_token.groups).to eq ['new-group']
      end
    end

    context 'when token value is passed in arguments' do
      it 'sets value of a token to one passed in args' do
        tokens, new_token = subject.create_or_update_token(
          kubernetes_identity.data,
          kubernetes_identity.id,
          'production',
          'g1,g2,g3',
          'token-value-passed-in-arguments'
        )

        expect(ENCRYPTOR.decrypt(new_token.token)).to eq 'token-value-passed-in-arguments'
      end
    end
  end

  describe '.escalate_token' do
    let(:privileged_group) { 'privileged-group' }
    let(:expires_in_secs) { 180 }

    context 'when token for given cluster does not exist' do
      before do
        allow(kubernetes_identity).to receive(:data) { { tokens: [] } }
      end

      it 'returns nil as privileged_token' do
        tokens, privileged_token = subject.escalate_token(
          kubernetes_identity.data, 
          'some-cluster', 
          privileged_group,
          expires_in_secs
        )

        expect(tokens.size).to eq 0
        expect(privileged_token).to be nil
      end
    end

    context 'when token for given cluster exists' do
      before do
        allow(kubernetes_identity).to receive(:data) { { tokens: [kube_token] } }
        move_time_to now
      end

      it 'adds privileged_group to existing token groups and updates privilege expiration time and returns a <tokens, privileged_token> tupple' do
        tokens, privileged_token = subject.escalate_token(
          kubernetes_identity.data, 
          cluster, 
          privileged_group,
          expires_in_secs
        )
        expect(tokens.size).to eq 1
        expect(privileged_token.identity_id).to eq kubernetes_identity.id
        expect(privileged_token.cluster).to eq cluster
        expect(ENCRYPTOR.decrypt(privileged_token.token)).to eq token
        expect(privileged_token.uid).to_not be_empty

        expected_groups = groups.nil? ? [ privileged_group ] : groups << privileged_group

        expect(privileged_token.groups).to match_array expected_groups
        expect(privileged_token.expire_privileged_at).to eq expires_in_secs.seconds.from_now
      end

      it 'limit expire_privileged_at to 6h max' do
        tokens, privileged_token = subject.escalate_token(
          kubernetes_identity.data, 
          cluster, 
          privileged_group,
          30000
        )
        expect(tokens.size).to eq 1
        expect(privileged_token.expire_privileged_at).to eq 21600.seconds.from_now
      end

      context 'with subsequent privileged_group update' do
        it 'keeps unique list of groups per token and updates expire_privileged_at time' do
          subject.escalate_token(
            kubernetes_identity.data, 
            cluster, 
            privileged_group,
            10
          )
          tokens, privileged_token = subject.escalate_token(
            kubernetes_identity.data, 
            cluster, 
            privileged_group,
            expires_in_secs
          )
          expect(tokens.size).to eq 1
          expect(privileged_token.identity_id).to eq kubernetes_identity.id
          expect(privileged_token.cluster).to eq cluster
          expect(ENCRYPTOR.decrypt(privileged_token.token)).to eq token
          expect(privileged_token.uid).to_not be_empty

          expected_groups = groups.nil? ? [ privileged_group ] : groups << privileged_group

          expect(privileged_token.groups).to match_array expected_groups
          expect(privileged_token.expire_privileged_at).to eq expires_in_secs.seconds.from_now
        end
      end
    end
  end

  describe '.delete_token' do
    it 'removes cluster token and returns a <tokens, deleted_token> tupple' do
      tokens, deleted_token = subject.delete_token(kubernetes_identity.data, cluster)
      expect(tokens.size).to eq 0
      expect(deleted_token.cluster).to eq cluster
      expect(ENCRYPTOR.decrypt(deleted_token.token)).to eq token
      expect(deleted_token.uid).to eq uid
    end
  end

  describe '.generate_secure_random' do
    it 'returns secure random uuid' do
      token = subject.send(:generate_secure_random)
      expect(token).to_not be_empty
      expect(token.length).to eq 36
    end
  end

  describe '.cleanup_groups' do
    let(:groups) { 'group1,  group2     ,group3 , , , group4, group1' }
    
    it 'parses comma separated list of groups and converts it to de-dupped array' do
      expect(subject.cleanup_groups(groups)).to match_array(['group1','group2','group3','group4'])
    end
  end

  describe '.token_value' do
    context 'with no initial token passed as argument' do
      it 'returns new unencrypted token value' do
        val = subject.token_value
        expect(val.length).to eq 36
        expect(ENCRYPTOR.decrypt(val)).to be_nil
      end
    end

    context 'with initial token passed in argument' do
      context 'as encrypted value' do
        let(:plain_token_value) { 'some-initial-token' }
        let(:initial_token) { ENCRYPTOR.encrypt(plain_token_value) }

        it 'decrypts and returns it' do
          expect(subject.token_value(initial_token)).to eq plain_token_value
        end
      end
      
      context 'as plain string' do
        let(:plain_token_value) { 'some-initial-token' }

        it 'returns it' do
          expect(subject.token_value(plain_token_value)).to eq plain_token_value
        end
      end
    end
  end

end
