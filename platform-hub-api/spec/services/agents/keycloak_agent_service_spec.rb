require 'rails_helper'

describe Agents::KeycloakAgentService, type: :service do
  let(:base_url) { 'base_url' }
  let(:realm) { 'realm' }
  let(:client_id) { 'client_id' }
  let(:client_secret) { 'client_secret' }
  let(:username) { 'username' }
  let(:password) { 'password' }

  subject do
    Agents::KeycloakAgentService.new(
      base_url: base_url,
      realm: realm,
      client_id: client_id,
      client_secret: client_secret,
      username: username,
      password: password,
    )
  end

  describe '#client' do
    it 'instantiate new http client with appropriate URL' do
      expect(Faraday).to receive(:new).with base_url
      subject.client
    end
  end

  describe '#bearer_token' do
    context 'when token was previously obtained and has not expired' do
      let(:token) { JWT.encode({ 'exp' => 10.minutes.from_now.to_i }, nil, false) }

      before do
        subject.instance_variable_set('@token', token)
      end

      it 'returns it' do
        expect(subject.bearer_token).to be token
      end
    end

    context 'when token was not previously obtained or is expired' do
      let(:token) { JWT.encode({ 'exp' => 1.minute.ago.to_i }, nil, false) }
      let(:client) { double }

      before do
        subject.instance_variable_set('@token', token)
        expect(subject).to receive(:client) { client }

        expect(client).to receive(:post).with(
          "/realms/#{realm}/protocol/openid-connect/token",
          {
            client_id: client_id,
            client_secret: client_secret,
            username: username,
            password: password,
            grant_type: 'password'
          }
        ).and_return(response)
      end

      context 'with successful API call to obtain new bearer token' do
        let(:new_token) do
          # construct test JWT token
          # we're not interested in other fields than 'exp' for test
          JWT.encode({ 'exp' => 10.minutes.from_now.to_i }, nil, false)
        end
        let(:body) do
          {
            'access_token' => new_token # let's skip other fields
          }
        end

        let(:response) { double(success?: true, body: body.to_json) }

        it 'returns access token extracted from API response' do
          res = subject.bearer_token
          expect(res).to eq new_token
          expect(subject.instance_variable_get('@token')).to eq new_token
        end
      end

      context 'with unsuccessful API call to obtain new bearer token' do
        let(:response) { double(success?: false, body: 'unsuccessful response body') }

        it 'raises KeycloakAccessTokenRequestFailed exception' do
          expect(Rails.logger).to receive(:error)
            .with "Couldn't obtain access token from Keycloak. Response: #{response.body}"

          expect { subject.bearer_token }
            .to raise_error Agents::KeycloakAgentService::Errors::KeycloakAccessTokenRequestFailed
        end
      end
    end
  end

  describe '#update_enabled_state' do
    let(:user) { double }
    let(:representation) do
      {
        'enabled' => false # let's ignore other fields in user representation
      }
    end
    let(:expected_representation) do
      {
        'enabled' => true
      }
    end

    context 'with valid token' do
      it 'updates user representation by setting correct enable flag' do
        expect(subject).to receive(:get_user_representation).with(user) { representation }
        expect(subject).to receive(:update_user).with(expected_representation)

        subject.update_enabled_state(user, true)
      end
    end

    context 'with expired bearer token' do
      before do
        # Raise exception first time
        expect(subject).to receive(:get_user_representation).with(user)
          .and_raise Agents::KeycloakAgentService::Errors::KeycloakAccessTokenExpired
        # Return representation on second call
        expect(subject).to receive(:get_user_representation).with(user)
          .and_return representation
      end

      it 'handles KeycloakAccessTokenExpired exception by retrying' do
        expect(subject).to receive(:update_user).with(expected_representation)

        subject.update_enabled_state(user, true)
      end
    end
  end

  describe '#deactivate_user' do
    let(:user) { double }

    it 'calls update_enabled_state method with correct value' do
      expect(subject).to receive(:update_enabled_state).with(user, false)
      subject.deactivate_user user
    end
  end

  describe '#activate_user' do
    let(:user) { double }

    it 'calls update_enabled_state method with correct value' do
      expect(subject).to receive(:update_enabled_state).with(user, true)
      subject.activate_user user
    end
  end

  describe 'private methods' do

    describe '#get_user_representation' do
      let(:user) { double }

      context 'with missing user keycloak identity' do
        before do
          expect(user).to receive(:identity).with(:keycloak) { nil }
        end

        it 'raises KeycloakIdentityMissing exception' do
          expect { subject.send(:get_user_representation, user) }
            .to raise_error Agents::KeycloakAgentService::Errors::KeycloakIdentityMissing
        end
      end

      context 'with user keycloak identity present' do
        let(:keycloak_user_id) { 'keycloak-user-id' }
        let(:keycloak_identity) { double(external_id: keycloak_user_id) }
        let(:client) { double }
        let(:bearer_token) { 'some-bearer-token' }

        before do
          expect(user).to receive(:identity).with(:keycloak) { keycloak_identity }

          expect(subject).to receive(:client) { client }
          expect(subject).to receive(:bearer_token) { bearer_token }
          expect(client).to receive(:get).with(
            "/admin/realms/#{realm}/users/#{keycloak_user_id}",
            {},
            {
              'Authorization': "Bearer #{bearer_token}"
            }
          ).and_return(response)
          expect(subject).to receive(:handle).with(response)
        end

        context 'with successful API call' do
          let(:representation) do
            {
              'id' => keycloak_user_id, # let's skip other fields
            }
          end
          let(:response) { double(success?: true, body: representation.to_json)}

          it 'returns parsed JSON response' do
            expect(subject.send(:get_user_representation, user)).to eq representation
          end
        end

        context 'with unsuccessful API call' do
          let(:response) { double(success?: false, body: 'unsuccessful response body')}

          it 'raises KeycloakUserRepresentationMissing exception' do
            expect { subject.send(:get_user_representation, user) }
              .to raise_error Agents::KeycloakAgentService::Errors::KeycloakUserRepresentationMissing
          end
        end
      end
    end

    describe '#update_user' do
      context 'with empty user representation' do
        it 'raises KeycloakUserRepresentationMissing exception' do
          expect(Rails.logger).to receive(:error)
            .with 'Keycloak user representation missing and will not be updated.'
          expect { subject.send(:update_user) }
            .to raise_error Agents::KeycloakAgentService::Errors::KeycloakUserRepresentationMissing
        end
      end

      context 'with user representation present' do
        let(:client) { double }
        let(:bearer_token) { 'some-bearer-token' }
        let(:keycloak_user_id) { 'keycloak-user-id' }
        let(:representation) do
          {
            'id' => keycloak_user_id, # let's ignore other fields in user representation
          }
        end

        before do
          expect(subject).to receive(:client) { client }
          expect(subject).to receive(:bearer_token) { bearer_token }
          expect(client).to receive(:put).with(
            "/admin/realms/#{realm}/users/#{keycloak_user_id}",
            representation.to_json,
            {
              'Authorization': "Bearer #{bearer_token}",
              'Content-Type': 'application/json'
            }
          ).and_return(response)
          expect(subject).to receive(:handle).with(response)
        end

        context 'with successful API call' do
          let(:response) { double(success?: true)}

          it 'returns updated user representation' do
            expect(Rails.logger).to receive(:info)
              .with 'User representation updated in Keycloak!'
            expect(subject.send(:update_user, representation)).to be representation
          end
        end

        context 'with unsuccessful API call' do
          let(:response) { double(success?: false, body: 'unsuccessful response body')}

          it 'raises KeycloakUserRepresentationUpdateFailed exception' do
            expect(Rails.logger).to receive(:error)
              .with "User representation hasn't been updated in Keycloak! Response: #{response.body}"
            expect { subject.send(:update_user, representation) }
              .to raise_error Agents::KeycloakAgentService::Errors::KeycloakUserRepresentationUpdateFailed
          end
        end
      end
    end

    describe '#handle' do
      context 'with response status 401 and `Bearer` as body' do
        let(:response) { double(status: 401, body: 'Bearer') }

        it 'raises KeycloakAccessTokenExpired exception' do
          expect { subject.send(:handle, response) }
            .to raise_error Agents::KeycloakAgentService::Errors::KeycloakAccessTokenExpired
        end
      end
    end

  end

end
