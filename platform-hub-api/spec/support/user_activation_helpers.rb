module UserActivationHelpers

  RSpec.shared_examples "verify responses to exceptions for user activation" do |action|

    def verify_response(action, message, logger_message)
      expect(Rails.logger).to receive(:error).with(logger_message)
      post action.to_sym, params: { id: @user.id }
      expect(json_response['error']['message']).to eq message
      expect(response).to have_http_status(:unprocessable_entity)
    end

    expected_messages = {
      # map of expected response messages to given exception
      KeycloakIdentityMissing: 'User keycloak identity missing',
      KeycloakUserRepresentationMissing: 'Could not retrieve user representation from Keycloak',
      KeycloakUserRepresentationUpdateFailed: 'Could not update user representation in Keycloak',
      KeycloakAccessTokenRequestFailed: 'Could not obtain Keycloak auth token',
    }

    expected_messages.keys.each do |exception|
      context "for #{exception}" do
        before do
          expect(UserActivationService).to receive("#{action}!".to_sym).with(@user)
            .and_raise "Agents::KeycloakAgentService::Errors::#{exception}".constantize
        end

        it 'renders appropriate response' do
          message = expected_messages[exception]
          logger_message = logger_message || message
          verify_response(action, message, logger_message)
        end
      end
    end

    context "for any other exception" do
      let(:error_class) { StandardError }
      let(:error_message) { 'Some other error' }
      let(:message) { 'User status change failed' }
      let(:logger_message) { "User status change failed - #{error_class}: #{error_message}" }

      before do
        expect(UserActivationService).to receive("#{action}!".to_sym).with(@user)
          .and_raise error_class, error_message
      end

      it 'renders appropriate response' do
        verify_response(action, message, logger_message)
      end
    end

  end

end
