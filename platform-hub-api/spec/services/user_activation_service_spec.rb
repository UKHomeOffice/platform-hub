require 'rails_helper'

describe UserActivationService, type: :service do
  let(:user) { create :user }
  let(:keycloak_agent_service) { instance_double('Agents::KeycloakAgentService') }
  let(:git_hub_agent_service) { instance_double('Agents::GitHubAgentService') }

  describe '.activate!' do

    before do
      expect(subject).to receive(:keycloak_agent_service) { keycloak_agent_service }
      expect(keycloak_agent_service).to receive(:activate_user).with(user)
    end

    context 'when user does not have a Github identity connected' do
      it 'activates user locally and in keycloak' do
        expect(subject).to receive(:git_hub_agent_service).never

        expect(user).to receive(:activate!)
        subject.activate! user
      end
    end

    context 'when user has a Github identity connected' do
      before do
        create :github_identity, user: user
      end

      it 'activates the user locally and in keycloak, and attempts to onboard to Github' do
        expect(subject).to receive(:git_hub_agent_service) { git_hub_agent_service }
        expect(git_hub_agent_service).to receive(:onboard_user).with(user)

        expect(user).to receive(:activate!)
        subject.activate! user
      end
    end

  end

  describe '.deactivate!' do

    before do
      expect(subject).to receive(:keycloak_agent_service) { keycloak_agent_service }
      expect(keycloak_agent_service).to receive(:deactivate_user).with(user)
    end

    context 'when user does not have a Github identity connected' do
      it 'deactivates user locally and in keycloak' do
        expect(subject).to receive(:git_hub_agent_service).never

        expect(user).to receive(:deactivate!)
        subject.deactivate! user
      end
    end

    context 'when user has a Github identity connected' do
      before do
        create :github_identity, user: user
      end

      it 'deactivates the user locally and in keycloak, and attempts to offboard from Github' do
        expect(subject).to receive(:git_hub_agent_service) { git_hub_agent_service }
        expect(git_hub_agent_service).to receive(:offboard_user).with(user)

        expect(user).to receive(:deactivate!)
        subject.deactivate! user
      end
    end

  end

end
