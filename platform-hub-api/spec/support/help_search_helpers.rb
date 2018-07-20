module HelpSearchHelpers

  RSpec.shared_context 'help search helpers' do

    let(:help_search_service_instance) { instance_double('HelpSearchService') }

    before do
      allow(HelpSearchService).to receive(:instance)
        .and_return(help_search_service_instance)
    end

  end

end
