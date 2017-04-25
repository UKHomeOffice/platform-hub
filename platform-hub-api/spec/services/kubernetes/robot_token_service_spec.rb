require 'rails_helper'

describe Kubernetes::RobotTokenService, type: :service do

  let(:cluster) { :development }
  let(:token) { 'robot-token' }
  let(:user) { 'robot-user' }
  let(:uid) { 'robot-user' }
  let(:groups) { ['robot-group'] }

  before do
    create(:hash_record,
      id: 'development-static-robot-tokens',
      scope: 'kubernetes',
      data: [
        {token: token, user: user, uid: uid, groups: groups}
      ]
    )

    @robot_tokens = HashRecord.kubernetes.find_by!(id: "#{cluster.to_s}-static-robot-tokens")
  end

  describe '.create_or_update' do
    let(:new_groups) { ['g1','g2'] }

    context 'robot token does not exist yet' do
      let(:new_robot_user) { 'new-robot' }

      it 'creates a new robot account token' do
        expect {
          subject.create_or_update(cluster, new_robot_user, new_groups)
        }.to change { @robot_tokens.reload.data.size }.by(1)

        new_record = @robot_tokens.data.last
        expect(new_record['user']).to eq new_robot_user
        expect(new_record['groups']).to eq new_groups
        expect(new_record['token']).to_not be_empty
        expect(new_record['uid']).to_not be_empty
      end
    end

    context 'robot token already exist' do
      it 'updates existing robot account record' do
        expect {
          subject.create_or_update(cluster, user, new_groups)
        }.to change { @robot_tokens.reload.data.size }.by(0)

        existing_record = @robot_tokens.data.first
        expect(existing_record['user']).to eq user
        expect(existing_record['groups']).to eq new_groups
        expect(existing_record['token']).to eq token
        expect(existing_record['uid']).to eq uid
      end
    end
  end

  describe '.delete' do
    it 'removes robot account from the list' do
      expect {
        subject.delete(cluster, user)
      }.to change { @robot_tokens.reload.data.size }.by(-1)

      expect(@robot_tokens.data.size).to eq 0
    end
  end

  describe '.describe' do
    context 'when robot account does not exist' do
      it 'returns appropriate message' do
        res = subject.describe(cluster, 'non-existing-robot-account')
        expect(res).to eq "Account not found!"
      end
    end

    context 'when robot account exist' do
      it 'shows details about robot account token' do
        record = @robot_tokens.data.first
        res = subject.describe(cluster, user)
        expect(res).to eq record
      end
    end
  end

end
