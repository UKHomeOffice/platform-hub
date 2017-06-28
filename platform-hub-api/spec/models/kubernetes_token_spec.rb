require 'rails_helper'

RSpec.describe KubernetesToken, type: :model do

  let(:token) { 'some-token-value' }
  let(:new_token) { 'new-token-value' }

  before do
    @kube_token = build(:kubernetes_token, token: token)
  end

  describe '#new' do
    it 'encrypts plain token upon creation of a new object' do
      expect(@kube_token.token).to_not be_empty
      expect(@kube_token.token).to match /--[\p{Alnum}]{40}/
      expect(@kube_token.token).to_not eq token
    end

    it 'encrypts token on the fly when new value is set' do
      @kube_token.token = new_token
      expect(@kube_token.token).to match /--[\p{Alnum}]{40}/
      expect(@kube_token.token).to_not eq new_token
      expect(@kube_token.decrypted_token).to eq new_token
    end
  end

  describe '#decrypted_token' do
    it 'returns decrypted kubernetes token value' do
      expect(@kube_token.decrypted_token).to eq token
    end
  end

  describe '.from_data' do
    let(:cluster) { 'cluster' }
    let(:identity_id) { 'some-identity-id' }
    let(:uid) { 'some-uid' }
    let(:groups) { [ 'some-group' ] }

    let(:token_data_hash) do
      {
        identity_id: identity_id,
        cluster: cluster,
        token: ENCRYPTOR.encrypt(token),
        uid: uid,
        groups: groups
      }
    end

    it 'builds new KubernetesToken object from kubernetes identity data item' do
      res = KubernetesToken.from_data(token_data_hash.with_indifferent_access)
      expect(res.identity_id).to eq identity_id
      expect(res.cluster).to eq cluster
      expect(ENCRYPTOR.decrypt(res.token)).to eq token
      expect(res.uid).to eq uid
      expect(res.groups).to eq groups
    end
  end

end
