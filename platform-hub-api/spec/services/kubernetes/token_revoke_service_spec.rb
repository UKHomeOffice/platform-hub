require 'rails_helper'

describe Kubernetes::TokenRevokeService, type: :service do

  describe '.remove' do
    let(:token) { 'some-token' }    

    context 'when token has not been found' do
      before do
        expect(subject).to receive(:lookup_identities).with(token) { [] }
        expect(subject).to receive(:lookup_static_tokens).with(token, 'user') { [] }
        expect(subject).to receive(:lookup_static_tokens).with(token, 'robot') { [] }
      end

      it 'raises TokenNotFound error' do
        expect do
          subject.remove(token)
        end.to raise_error(
          Kubernetes::TokenRevokeService::Errors::TokenNotFound, "Token `#{token}` not found!"
        )
      end
    end

    context 'when token was found and is not associated with user kubernetes identity' do
      let(:cluster) { 'development' }
      let(:kind) { 'user' }
      let(:user) { build(:user) }
      let(:lookup_results) { [ double(user: nil, cluster: cluster, kind: kind) ] }

      before do
        expect(subject).to receive(:lookup_identities).with(token) { [] }
        expect(subject).to receive(:lookup_static_tokens).with(token, kind) { lookup_results }
      end

      it 'deletes static token' do
        expect(Kubernetes::StaticTokenService).to receive(:delete_by_token).with(cluster, kind, token)
        res = subject.remove(token)
        expect(res).to match [[ cluster, "Revoked `#{cluster}` token in #{kind} static tokens" ]]
      end
    end

    context 'when token was found and is associated with user kubernetes identity' do
      let(:cluster) { 'development' }
      let(:user) { build(:user) }
      let(:lookup_results ) { [ double(user: user, cluster: cluster) ] }

      let(:new_tokens) { double }
      let(:removed_token) { double }

      let(:user_kubernetes_identity) { double }
      let(:user_kubernetes_identity_data) { double }

      before do
        expect(subject).to receive(:lookup_identities).with(token) { lookup_results }
      end

      it 'deletes token from user kubernetes identity' do
        expect(user).to receive(:identity).with(:kubernetes) { user_kubernetes_identity }
        allow(user_kubernetes_identity).to receive(:data) { user_kubernetes_identity_data }
        expect(Kubernetes::TokenService).to receive(:delete_token)
          .with(user_kubernetes_identity_data, cluster) { [ new_tokens, removed_token ] }
        expect(removed_token).to receive(:[]).with('token') { ENCRYPTOR.encrypt(token) }
        expect(user_kubernetes_identity).to receive(:with_lock).and_yield
        expect(user_kubernetes_identity_data).to receive(:[]=).with('tokens', new_tokens)
        expect(user_kubernetes_identity).to receive(:save!)
        res = subject.remove(token)
        expect(res).to match [[ cluster, "Revoked `#{cluster}` token in `#{user.email}` kubernetes identity" ]]
      end
    end
  end

end
