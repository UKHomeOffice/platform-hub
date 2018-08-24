require 'rails_helper'

RSpec.describe DocsSyncJob, type: :job do

  describe '.is_already_queued?' do
    it 'should recognise when the job is already queued' do
      expect(DocsSyncJob.is_already_queued?).to be false

      DocsSyncJob.perform_later

      expect(DocsSyncJob.is_already_queued?).to be true
    end
  end

  describe '.perform' do

    let(:help_search_service) { instance_double('HelpSearchService') }
    let(:docs_sync_service) { instance_double('Docs::DocsSyncService') }

    before do
      allow(HelpSearchService).to receive(:instance).and_return(help_search_service)
    end

    context 'with docs_sync feature flag enabled' do
      before do
        FeatureFlagService.create_or_update(:docs_sync, true)
      end

      it 'should call the DocsSyncService' do
        expect(Docs::DocsSyncService).to receive(:new)
          .with(help_search_service: help_search_service)
          .and_return(docs_sync_service)
        expect(docs_sync_service).to receive(:sync_all)

        DocsSyncJob.new.perform
      end
    end

    context 'with docs_sync feature flag disabled' do
      before do
        FeatureFlagService.create_or_update(:docs_sync, false)
      end

      it 'should not do anything' do
        expect(Docs::DocsSyncService).to receive(:new).never

        DocsSyncJob.new.perform
      end
    end

  end

end
