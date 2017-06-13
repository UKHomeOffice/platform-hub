require 'rails_helper'

describe Kubernetes::TokenFileService, type: :service do

  let(:cluster) { :development }
  let(:kind) { :robot }

  before do
    create(:hash_record,
      id: 'development-static-system-tokens',
      scope: 'kubernetes',
      data: [
        {token: ENCRYPTOR.encrypt('system-token'), user: 'system-user', uid: 'system-uid', groups: ['system-group']}
      ]
    )
    create(:hash_record,
      id: 'development-static-user-tokens',
      scope: 'kubernetes',
      data: [
        {token: ENCRYPTOR.encrypt('user-token'), user: 'user-user', uid: 'user-uid', groups: ['user-group']}
      ]
    )
    create(:hash_record,
      id: 'development-static-robot-tokens',
      scope: 'kubernetes',
      data: [
        {token: ENCRYPTOR.encrypt('robot-token'), user: 'robot-user', uid: 'robot-uid', groups: ['robot-group']}
      ]
    )    
  end

  describe '.generate' do
    let(:token) { 'some-token' }
    let(:uid) { 'some-uid' }
    let(:groups) { ['group1', 'group2'] }
    let(:kubernetes_identity) do
      instance_double('Identity', provider: :kubernetes, user: build(:user), data: {
        tokens: [
          build(:kubernetes_token, cluster: cluster, token: token, uid: uid, groups: groups)
        ]
      })
    end

    before do
      allow(Identity).to receive_message_chain(:kubernetes, :find_each)
        .with(batch_size: Kubernetes::TokenFileService::IDENTITY_BATCH_SIZE)
        .and_yield(kubernetes_identity)
    end

    it 'compiles csv for static and platform managed tokens for given cluster' do
      tokens_csv = subject.generate(cluster)
      parsed = CSV.parse(tokens_csv)
      expect(parsed.size).to eq 4
      expect(parsed[0][0]).to eq 'system-token'
      expect(parsed[1][0]).to eq 'user-token'
      expect(parsed[2][0]).to eq 'robot-token'
      t = parsed.last
      expect(t[0]).to eq token
      expect(t[1]).to eq kubernetes_identity.user.email
      expect(t[2]).to eq uid
      expect(t[3]).to eq groups.join(',')
    end
  end

  describe 'private methods' do

    describe '.static_tokens' do
      it 'returns static tokens for given cluster and kind' do
        tokens = subject.send(:static_tokens, cluster, kind)
        expect(tokens).to_not be_empty
        expect(tokens.size).to eq 1
        t = tokens.first
        expect(ENCRYPTOR.decrypt(t['token'])).to eq "#{kind}-token"
        expect(t['user']).to eq "#{kind}-user"
        expect(t['uid']).to eq "#{kind}-uid"
        expect(t['groups']).to eq ["#{kind}-group"]
      end

      it 'raises exception for not supported kind' do
        expect do
         subject.send(:static_tokens, cluster, 'not-supported-kind')
        end.to raise_exception(
          Kubernetes::TokenFileService::Errors::UnknownStaticTokensKind,
          '`not-supported-kind` kind not supported.'
        )
      end
    end

  end
end

