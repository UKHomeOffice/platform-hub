require 'rails_helper'

describe Kubernetes::StaticTokenService, type: :service do

  let(:cluster) { :development }
  let(:kind) { 'user' }
  
  let(:token) { 'token' }
  let(:user) { 'user' }
  let(:uid) { 'uid' }
  let(:groups) { ['group'] }
  
  let(:other_token) { 'other_token' }
  let(:other_user) { 'other_user' }
  let(:other_uid) { 'other_uid' }
  let(:other_groups) { ['other_group'] }
  
  before do
    create(:kubernetes_static_tokens_hash_record,
      id: "#{cluster.to_s}-static-#{kind.to_s}-tokens",
      data: [
        {token: ENCRYPTOR.encrypt(token), user: user, uid: uid, groups: groups},
        {token: ENCRYPTOR.encrypt(other_token), user: other_user, uid: other_uid, groups: other_groups}
      ]
    )
    @static_tokens = HashRecord.kubernetes.find_by!(id: "#{cluster.to_s}-static-#{kind.to_s}-tokens")
  end

  describe '.create_or_update' do
    let(:new_groups) { ['g1','g2'] }

    context 'static token does not exist yet' do
      let(:new_user_name) { 'new-user-name' }

      it 'creates a new static account token' do
        expect {
          subject.create_or_update(cluster, kind, new_user_name, new_groups)
        }.to change { @static_tokens.reload.data.size }.by(1)

        new_record = @static_tokens.data.last
        expect(new_record['user']).to eq new_user_name
        expect(new_record['groups']).to eq new_groups
        expect(new_record['token']).to_not be_empty
        expect(new_record['uid']).to_not be_empty
      end
    end

    context 'static token already exist' do
      it 'updates existing static account record' do
        expect {
          subject.create_or_update(cluster, kind, user, new_groups)
        }.to change { @static_tokens.reload.data.size }.by(0)

        existing_record = @static_tokens.data.first
        expect(existing_record['user']).to eq user
        expect(existing_record['groups']).to eq new_groups
        expect(ENCRYPTOR.decrypt(existing_record['token'])).to eq token
        expect(existing_record['uid']).to eq uid
      end
    end
  end

  describe '.delete_by_user_name' do
    it 'removes static account from the list by user name' do
      expect {
        subject.delete_by_user_name(cluster, kind, user)
      }.to change { @static_tokens.reload.data.size }.by(-1)

      expect(@static_tokens.data.size).to eq 1
    end
  end

  describe '.delete_by_token' do
    it 'removes statc account from the list by token' do
      expect {
        subject.delete_by_token(cluster, kind, token)
      }.to change { @static_tokens.reload.data.size }.by(-1)

      expect(@static_tokens.data.size).to eq 1
    end

  end

  describe '.describe' do
    context 'when static account does not exist' do
      it 'returns appropriate message' do
        res = subject.describe(cluster, kind, 'non-existing-static-account')
        expect(res).to eq "Account not found!"
      end
    end

    context 'when static account exist' do
      it 'shows details about static account token' do
        record = @static_tokens.data.first
        res = subject.describe(cluster, kind, user)
        expect(res).to eq record
      end
    end
  end

end
