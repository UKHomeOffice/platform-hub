require 'rails_helper'

describe UserActivationService, type: :service do
  let(:user) { double }
  let(:keycloak_agent_service) { double }

  describe '.activate!' do
    it 'activates user locally and in keycloak' do
      expect(subject).to receive(:keycloak_agent_service) { keycloak_agent_service }
      expect(keycloak_agent_service).to receive(:activate_user).with(user)
      expect(user).to receive(:activate!)
      subject.activate! user
    end
  end

  describe '.deactivate!' do
    it 'deactivates user locally and in keycloak' do
      expect(subject).to receive(:keycloak_agent_service) { keycloak_agent_service }
      expect(keycloak_agent_service).to receive(:deactivate_user).with(user)
      expect(user).to receive(:deactivate!)
      subject.deactivate! user
    end
  end

end
