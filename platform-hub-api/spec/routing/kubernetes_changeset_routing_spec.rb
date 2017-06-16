require 'rails_helper'

RSpec.describe Kubernetes::ChangesetController, type: :routing do
  describe 'routing' do

    it 'routes to #index' do
      expect(:get => '/kubernetes/changeset/development').to route_to('kubernetes/changeset#index', :cluster => 'development')
    end

  end
end
