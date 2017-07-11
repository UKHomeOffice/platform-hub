require 'rails_helper'

describe AuthUserService, type: :service do

  # Typically, service tests should be more "unit-y", with minimal dependencies
  # and mocking out boundaries. We make an exception in this particular case:
  # we allow persistence to the db, and we check the db state explicitly
  # given the nature of this service (since it's sole responsibility is to map
  # auth tokens to users, creating a new one if needed).

  include_context 'authentication helpers'

  describe ".get" do
    before do
      @user = AuthUserService.get auth_token_payload
    end

    context 'with an empty auth_token_payload' do
      let :auth_token_payload do
        nil
      end

      it 'should return nil' do
        expect(@user).to be_nil
      end

      it 'should not have persisted anything' do
        expect(User.count).to eq 0
        expect(Identity.count).to eq 0
      end
    end

    context 'with a valid auth_token_payload' do
      let :auth_token_payload do
        test_auth_payload
      end

      it 'should return a valid User model' do
        expect(@user).not_to be_nil
        expect(@user.valid?).to be true
      end

      it 'should have persisted a new User and Identity record as expected' do
        expect(User.count).to eq 1
        expect(Identity.count).to eq 1

        user_record = User.first
        identity_record = Identity.first

        expect(user_record).to eq @user
        expect(user_record.main_identity).to eq identity_record

        expect(user_record.id).to eq test_auth_payload.sub
        expect(user_record.name).to eq test_auth_payload.name
        expect(user_record.email).to eq test_auth_payload.email

        expect(identity_record.user_id).to eq user_record.id
        expect(identity_record.provider).to eq 'keycloak'
        expect(identity_record.external_id).to eq test_auth_payload.sub
        expect(identity_record.external_username).to eq test_auth_payload.preferred_username
        expect(identity_record.external_name).to eq test_auth_payload.name
        expect(identity_record.external_email).to eq test_auth_payload.email
        expect(identity_record.data).to eq test_auth_payload
      end
    end
  end

  describe '.touch_and_update_main_identity' do
    let(:user) { double }
    let(:main_identity) { double(external_id: keycloak_external_id) }
    let(:auth_payload) do
      { 'sub' => keycloak_payload_sub } # only sub to simplify
    end

    before do
      expect(main_identity).to receive(:with_lock).and_yield
      expect(user).to receive(:with_lock).and_yield
    end

    context 'with keycloak external_id unchanged' do
      let(:keycloak_external_id) { 'old-id' }
      let(:keycloak_payload_sub) { 'old-id' }

      it 'touches last_seen_at' do
        expect(user).to receive(:main_identity) { main_identity }
        expect(user).to receive(:touch).with(:last_seen_at)
        expect(main_identity).to receive(:update!).never
        subject.touch_and_update_main_identity user, auth_payload
      end
    end

    context 'with keycloak externa_id changed' do
      let(:keycloak_external_id) { 'old-id' }
      let(:keycloak_payload_sub) { 'new-id' }

      it 'touches last_seen_at and updates main identity external_id' do
        expect(user).to receive(:main_identity) { main_identity }
        expect(user).to receive(:touch).with(:last_seen_at)
        expect(main_identity).to receive(:update!).with(external_id: keycloak_payload_sub)
        subject.touch_and_update_main_identity user, auth_payload
      end
    end
  end

end
