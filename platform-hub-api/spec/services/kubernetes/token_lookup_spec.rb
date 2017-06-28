require 'rails_helper'

describe Kubernetes::TokenLookup, type: :service do

  subject do
    module Dummy
      extend Kubernetes::TokenLookup
    end
  end

  describe '.lookup' do
    let(:lookup_result) { double }

    context 'when token was found in static tokens' do
      before do
        expect(subject).to receive(:lookup_static_tokens) { lookup_result }
      end

      it 'returns it' do
        expect(subject).to receive(:lookup_identities).never
        expect(subject.lookup('some-token')).to eq lookup_result
      end
    end

    context 'when token was not found in static tokens' do
      before do
        expect(subject).to receive(:lookup_static_tokens) { nil }
      end

      it 'tries to find it in identities' do
        expect(subject).to receive(:lookup_identities) { lookup_result }
        expect(subject.lookup('some-token')).to eq lookup_result
      end
    end

  end

  describe '.lookup_static_tokens' do
    let(:cluster) { 'development' }
    let(:kind) { 'user' }
    let(:plain_user_token) { 'user-token' }
    let(:user_token) { ENCRYPTOR.encrypt(plain_user_token) }
    let(:user_uid) { 'user-uid' }
    let(:user_groups) { ['user-group'] }

    before do
      create(:kubernetes_clusters_hash_record)
      create(:kubernetes_static_tokens_hash_record,
        id: "#{cluster.to_s}-static-#{kind.to_s}-tokens",
        data: [
          {token: user_token, user: 'some-user', uid: user_uid, groups: user_groups}
        ]
      )
    end

    context 'when user token exist in static tokens list' do
      it 'returns found token struct' do
        res = subject.lookup_static_tokens(plain_user_token, kind)
        expect(res).to_not be_nil
        expect(res.cluster).to eq cluster
        expect(res.kind).to eq kind
        expect(res.user).to be_nil
        expect(res.data.token).to eq user_token
        expect(res.data.uid).to eq user_uid
        expect(res.data.groups).to match user_groups
      end
    end

    context 'when user token does not exist in static tokens list' do
      it 'returns nil' do
        res = subject.lookup_static_tokens('unknown-token', kind)
        expect(res).to be_nil

        res = subject.lookup_static_tokens(plain_user_token, 'robot')
        expect(res).to be_nil
      end
    end
  end

  describe '.lookup_identities' do
    let(:cluster) { 'development' }
    let(:plain_user_token) { 'user-token' }
    let(:user_token) { ENCRYPTOR.encrypt(plain_user_token) }
    let(:user_uid) { 'user-uid' }
    let(:user_groups) { ['user-group'] }

    before do
      @kubernetes_identity = FactoryGirl.build(:kubernetes_identity,
        data: {
          tokens: [
            {
              cluster: cluster, 
              token: user_token, 
              uid: user_uid, 
              groups: user_groups
            }
          ]
        }
      )

      allow(Identity).to receive_message_chain(:kubernetes, :find_each)
        .with(batch_size: Kubernetes::TokenLookup::IDENTITY_BATCH_SIZE)
        .and_yield(@kubernetes_identity)
    end

    context 'when user token belongs to any kubernetes identity' do        
      it 'returns found token struct' do
        res = subject.lookup_identities(plain_user_token)
        expect(res).to_not be_nil
        expect(res.cluster).to eq 'development'
        expect(res.user).to eq @kubernetes_identity.user
        expect(res.data.token).to eq user_token
        expect(res.data.uid).to eq user_uid
        expect(res.data.groups).to match user_groups
      end
    end

    context 'when user token does not belong to any kubernetes identity' do
      it 'returns nil' do
        res = subject.lookup_identities('unknown-token')
        expect(res).to be_nil
      end
    end
  end

end
