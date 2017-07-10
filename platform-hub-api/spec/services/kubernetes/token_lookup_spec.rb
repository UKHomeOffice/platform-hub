require 'rails_helper'

describe Kubernetes::TokenLookup, type: :service do

  subject do
    module Dummy
      extend Kubernetes::TokenLookup
    end
  end

  describe '.lookup' do
    let(:lookup_result) { [ double ] }

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
        expect(subject).to receive(:lookup_static_tokens) { [] }
      end

      it 'tries to find it in identities' do
        expect(subject).to receive(:lookup_identities) { lookup_result }
        expect(subject.lookup('some-token')).to eq lookup_result
      end
    end

  end

  describe '.lookup_static_tokens' do
    let(:dev_cluster) { 'development' }
    let(:prod_cluster) { 'production' }
    let(:kind) { 'user' }
    let(:plain_user_token) { 'user-token' }
    let(:user_token) { ENCRYPTOR.encrypt(plain_user_token) }
    let(:user_uid) { 'user-uid' }
    let(:user_dev_groups) { ['user-dev-group'] }
    let(:user_prod_groups) { ['user-prod-group'] }

    before do
      create(:kubernetes_clusters_hash_record)
      create(:kubernetes_static_tokens_hash_record,
        id: "#{dev_cluster.to_s}-static-#{kind.to_s}-tokens",
        data: [
          {token: user_token, user: 'some-dev-user', uid: user_uid, groups: user_dev_groups}
        ]
      )
      create(:kubernetes_static_tokens_hash_record,
        id: "#{prod_cluster.to_s}-static-#{kind.to_s}-tokens",
        data: [
          {token: user_token, user: 'some-prod-user', uid: user_uid, groups: user_prod_groups}
        ]
      )
    end

    context 'when user token exists in one or more static tokens lists' do
      it 'returns an array of found token structs' do
        res = subject.lookup_static_tokens(plain_user_token, kind)
        expect(res).to_not be_nil
        expect(res).to be_kind_of(Array)
        expect(res.size).to eq 2

        dev = res.first
        prod = res.second

        expect(dev.kind).to eq kind
        expect(dev.user).to be_nil
        expect(dev.data.token).to eq user_token
        expect(dev.data.uid).to eq user_uid
        expect(dev.data.groups).to match user_dev_groups

        expect(prod.kind).to eq kind
        expect(prod.user).to be_nil
        expect(prod.data.token).to eq user_token
        expect(prod.data.uid).to eq user_uid
        expect(prod.data.groups).to match user_prod_groups
      end
    end

    context 'when user token does not exist in any static tokens list' do
      it 'returns an empty array' do
        res = subject.lookup_static_tokens('unknown-token', kind)
        expect(res).to be_kind_of(Array)
        expect(res).to be_empty

        res = subject.lookup_static_tokens(plain_user_token, 'robot')
        expect(res).to be_kind_of(Array)
        expect(res).to be_empty
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
      it 'returns an array of found token structs' do
        res = subject.lookup_identities(plain_user_token)
        expect(res).to be_kind_of(Array)
        expect(res).to_not be_empty
        expect(res.size).to be 1

        t = res.first

        expect(t.cluster).to eq 'development'
        expect(t.user).to eq @kubernetes_identity.user
        expect(t.data.token).to eq user_token
        expect(t.data.uid).to eq user_uid
        expect(t.data.groups).to match user_groups
      end
    end

    context 'when user token does not belong to any kubernetes identity' do
      it 'returns an empty array' do
        res = subject.lookup_identities('unknown-token')
        expect(res).to be_kind_of(Array)
        expect(res).to be_empty
      end
    end
  end

end
