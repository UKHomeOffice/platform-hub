require 'rails_helper'

describe Kubernetes::TokenClaimService, type: :service do

  describe '.claim_token' do
    let(:user) { double }
    let(:token) { 'some-token' }

    context 'when token has not been found' do
      before do
        expect(subject).to receive(:lookup).with(token) { [] }
      end

      it 'raises TokenNotFound error' do
        expect do
          subject.claim_token(user, token)
        end.to raise_error(
          Kubernetes::TokenClaimService::Errors::TokenNotFound, "Token `#{token}` not found!"
        )
      end
    end

    context 'when token was found and is associated with user kubernetes identity' do
      let(:cluster) { 'development' }
      let(:claim) { double(user: user, cluster: cluster) }
      let(:claims) { [ claim ] }

      before do
        expect(subject).to receive(:lookup).with(token) { claims }
      end

      it 'overrides token value without modyfying anything else' do
        expect do
          subject.claim_token(user, token)
        end.to raise_error(
          Kubernetes::TokenClaimService::Errors::TokenAlreadyClaimed, "Token already claimed!"
        )
      end
    end

    context 'when token was found and is not associated with user kubernetes identity' do
      let(:cluster) { 'development' }
      let(:user) { build(:user) }
      let(:claim) { double(user: nil, cluster: cluster) }
      let(:claims) { [ claim ] }

      before do
        expect(subject).to receive(:lookup).with(token) { claims }
      end

      it 'migrates claimed token to user kubernetes identity and removes it from static list' do
        expect(subject).to receive(:migrate_claimed_token_to_user_kubernetes_identity).with(user, claim)
        expect(subject).to receive(:remove_claimed_token_from_static_list).with(claim)
        res = subject.claim_token(user, token)
        expect(res).to match [[ cluster, "Claimed `#{cluster}` token." ]]
      end

    end
  end

  describe 'private methods' do

    describe '.migrate_claimed_token_to_user_kubernetes_identity' do
      let(:cluster) { 'development' }
      let(:plain_user_token) { 'user-token' }
      let(:user_token) { ENCRYPTOR.encrypt(plain_user_token) }
      let(:user_uid) { 'user-uid' }
      let(:user_groups) { ['user-group'] }

      let(:existing_cluster) { 'production' }
      let(:existing_plain_user_token) { 'existing-user-token' }
      let(:existing_user_token) { ENCRYPTOR.encrypt(existing_plain_user_token) }
      let(:existing_user_uid) { 'existing-user-uid' }
      let(:existing_user_groups) { ['existing-user-group'] }

      let(:claim) do
        Hashie::Mash.new(
          cluster: cluster,
          data: {
            token: user_token,
            uid: user_uid,
            groups: user_groups,
          },
          user: nil
        )
      end

      before do
        # configure managed kubernetes clusters
        create(:kubernetes_clusters_hash_record,
          data: [
            {
              id: cluster,
              description: "#{cluster} cluster",
              # don't care about other cluster configuration in test
            },
            {
              id: existing_cluster,
              description: "#{existing_cluster} cluster",
              # don't care about other cluster configuration in test
            }
          ]
        )

        # create kubernetes identity with 1 existing kubernetes token
        @kubernetes_identity = create(:kubernetes_identity)
        @kubernetes_identity.update_attribute(:data, {
          tokens: [
            {
              identity_id: @kubernetes_identity.id,
              cluster: existing_cluster,
              token: existing_user_token,
              uid: existing_user_uid,
              groups: existing_user_groups
            }
          ]
        })
        @user = @kubernetes_identity.user
      end

      context 'when user does not have a token for claim token cluster' do
        it 'creates a new kubernetes token with data from claimed token' do
          expect(Kubernetes::TokenService).to receive(:create_or_update_token).with(
            @kubernetes_identity.data,
            @kubernetes_identity.id,
            claim.cluster,
            claim.data.groups,
            claim.data.token
          ).and_call_original

          subject.send(:migrate_claimed_token_to_user_kubernetes_identity, @user, claim)

          tokens = @kubernetes_identity.reload.data['tokens']
          expect(tokens.size).to eq 2

          added_token = tokens.last

          expect(added_token['cluster']).to eq cluster
          expect(ENCRYPTOR.decrypt(added_token['token'])).to eq plain_user_token
          expect(added_token['uid']).to_not be_empty
          expect(added_token['groups']).to eq user_groups
        end
      end

      context 'when user already have a token for same cluster as the claim token cluster' do

        before do
          # change claim data first to user same cluster as existing identity token cluster
          claim.merge!(cluster: existing_cluster)
        end

        it 'updates existing token in identity to the same value as claimed token - groups remain as set by admin' do
          expect(Kubernetes::TokenService).to receive(:create_or_update_token).with(
            @kubernetes_identity.data,
            @kubernetes_identity.id,
            existing_cluster,
            existing_user_groups,
            claim.data.token
          ).and_call_original

          subject.send(:migrate_claimed_token_to_user_kubernetes_identity, @user, claim)

          tokens = @kubernetes_identity.reload.data['tokens']
          expect(tokens.size).to eq 1

          existing_token = tokens.first

          expect(existing_token['cluster']).to eq existing_cluster
          expect(ENCRYPTOR.decrypt(existing_token['token'])).to eq plain_user_token
          expect(existing_token['uid']).to eq existing_user_uid
          expect(existing_token['groups']).to eq existing_user_groups
        end

      end

      context 'when claim token data renders new kubernetes token invalid' do
        before do
          @invalid_claim = claim.merge(cluster: nil)
        end

        it 'raises an exception with kubernetes token validation errors' do
          expect do
            subject.send(:migrate_claimed_token_to_user_kubernetes_identity, @user, @invalid_claim)
          end.to raise_error(
            Kubernetes::TokenClaimService::Errors::TokenInvalid
          )
        end
      end
    end

    describe '.remove_claimed_token_from_static_list' do
      let(:cluster) { 'development' }
      let(:plain_user_token) { 'user-token' }
      let(:user_token) { ENCRYPTOR.encrypt(plain_user_token) }

      let(:claim) do
        Hashie::Mash.new(
          cluster: cluster,
          data: {
            token: user_token,
            uid: 'some-uid',
            groups: [ 'some-group' ],
          },
          user: nil
        )
      end

      before do
        @dev_static_user_tokens = create(:kubernetes_static_tokens_hash_record,
          id: 'development-static-user-tokens',
          data: [
            {
              token: ENCRYPTOR.encrypt(plain_user_token),
              user: 'old-user',
              uid: 'old-uid',
              groups: [ 'old-group' ],
            }
          ]
        )
      end

      it 'removes claimed token from the static tokens hash record' do
        expect do
          subject.send(:remove_claimed_token_from_static_list, claim)
        end.to change { @dev_static_user_tokens.reload.data.size }.by(-1)
      end
    end

  end

end
