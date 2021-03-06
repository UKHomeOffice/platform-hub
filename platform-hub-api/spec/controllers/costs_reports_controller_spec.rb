require 'rails_helper'

RSpec.describe CostsReportsController, type: :controller do

  include_context 'time helpers'

  describe 'GET #available_data_files' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :available_data_files
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :available_data_files
        end
      end

      it_behaves_like 'a hub admin' do
        let(:filestore_service) { instance_double(FilestoreService) }

        let(:entries) do
          [ 'file1.csv', 'file2.csv' ]
        end

        it 'returns the list of available data files as expected' do
          expect(FilestoreService).to receive(:new)
            .with(any_args)
            .and_return(filestore_service)

          expect(filestore_service).to receive(:names).and_return(entries)

          get :available_data_files
          expect(json_response).to eq entries
        end
      end

    end
  end

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :index
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when no costs reports exist' do
          it 'returns an empty list' do
            get :index
            expect(response).to be_success
            expect(json_response).to be_empty
          end
        end

        context 'when costs reports exist' do
          before do
            @reports = create_list :costs_report, 3
          end

          let :total_reports do
            @reports.length
          end

          let :all_report_ids do
            @reports.map(&:id).reverse
          end

          it 'returns the existing costs reports ordered by id descending' do
            get :index
            expect(response).to be_success
            expect(json_response.length).to eq total_reports
            expect(pluck_from_json_response('id')).to match_array all_report_ids
          end
        end

      end

      it_behaves_like 'not a hub limited admin so forbidden'  do
        before do
          get :index
        end
      end

      it_behaves_like 'a hub limited admin' do

        context 'when no costs reports exist' do
          it 'returns an empty list' do
            get :index
            expect(response).to be_success
            expect(json_response).to be_empty
          end
        end

        context 'when costs reports exist' do
          before do
            @reports = create_list :costs_report, 3
          end

          let :total_reports do
            @reports.length
          end

          let :all_report_ids do
            @reports.map(&:id).reverse
          end

          it 'returns the existing costs reports ordered by id descending' do
            get :index
            expect(response).to be_success
            expect(json_response.length).to eq total_reports
            expect(pluck_from_json_response('id')).to match_array all_report_ids
          end
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @report = create :costs_report
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @report.id }
      end
    end

    it_behaves_like 'authenticated' do

      def expect_report report
        get :show, params: { id: report.id }
        expect(response).to be_success
        expect(json_response).to eq({
          'id' => report.id,
          'year' => report.year,
          'month' => report.month,
          'billing_file' => report.billing_file,
          'metrics_file' => report.metrics_file,
          'notes' => report.notes,
          'created_at' => report.created_at.iso8601,
          'published_at' => nil,
          'config' => report.config,
          'results' => report.results
        })
      end

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show, params: { id: @report.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent report' do
          it 'should return a 404' do
            get :show, params: { id: '2111-05' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a report that exists' do
          it 'should return the specified report resource' do
            expect_report @report
          end
        end

      end

      it_behaves_like 'not a hub limited admin so forbidden'  do
        before do
          get :show, params: { id: @report.id }
        end
      end

      it_behaves_like 'a hub limited admin' do

        context 'for a report that exists' do
          it 'should return the specified report resource' do
            expect_report @report
          end
        end

      end

    end
  end

  describe 'POST #prepare' do
    let :post_data do
      {
        year: 2017,
        month: 'Dec',
        billing_file: 'billing.csv',
        metrics_file: 'metrics.csv'
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :prepare, params: post_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :prepare, params: post_data
        end
      end

      it_behaves_like 'a hub admin' do

        let(:billing_data_service) { instance_double('Costs::BillingDataService') }
        let(:metrics_data_service) { instance_double('Costs::MetricsDataService') }
        let(:project_lookup_cache_service) { instance_double('ProjectLookupCacheService') }
        let(:project_service_name_lookup_cache_service) { instance_double('ProjectServiceNameLookupCacheService') }

        let(:generator_service) { instance_double('Costs::ReportResultsGeneratorService') }

        let(:results) do
          {
            'foo' => 'bar'
          }
        end

        it 'prepares the information for the costs report' do
          expect(controller).to receive(:billing_data_service)
            .and_return(billing_data_service)
          expect(controller).to receive(:metrics_data_service)
            .and_return(metrics_data_service)
          expect(controller).to receive(:project_lookup_cache_service)
            .and_return(project_lookup_cache_service)
          expect(controller).to receive(:project_service_name_lookup_cache_service)
            .and_return(project_service_name_lookup_cache_service)

          expect(Costs::ReportResultsGeneratorService).to receive(:new)
            .with(
              billing_data_service,
              metrics_data_service,
              project_lookup_cache_service,
              project_service_name_lookup_cache_service
            )
            .and_return(generator_service)
          expect(generator_service).to receive(:prepare_results)
            .and_return(results)

          expected_results = results.dup
          expected_results['exists'] = false
          expected_results['already_published'] = false

          post :prepare, params: post_data
          expect(response).to be_success
          expect(CostsReport.count).to eq 0
          expect(json_response).to eq expected_results
        end
      end

      it_behaves_like 'a hub limited admin' do
        it 'should be forbidden' do
          post :prepare, params: post_data
          expect(response).to have_http_status(403)
        end
      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      {
        year: 2017,
        month: 'Dec',
        notes: 'Foobar',
        billing_file: 'billing.csv',
        metrics_file: 'metrics.csv',
        config: { 'foo' => 'bar' }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :create, params: post_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :create, params: post_data
        end
      end

      it_behaves_like 'a hub admin' do

        let(:billing_data_service) { instance_double('Costs::BillingDataService') }
        let(:metrics_data_service) { instance_double('Costs::MetricsDataService') }
        let(:project_lookup_cache_service) { instance_double('ProjectLookupCacheService') }
        let(:project_service_name_lookup_cache_service) { instance_double('ProjectServiceNameLookupCacheService') }

        let(:generator_service) { instance_double('Costs::ReportResultsGeneratorService') }

        let(:results) { { 'something' => 'amazing' } }

        it 'creates a new report as expected' do
          expect(CostsReport.count).to eq 0
          expect(Audit.count).to eq 0

          expect(controller).to receive(:billing_data_service)
            .and_return(billing_data_service)
          expect(controller).to receive(:metrics_data_service)
            .and_return(metrics_data_service)
          expect(controller).to receive(:project_lookup_cache_service)
            .and_return(project_lookup_cache_service)
          expect(controller).to receive(:project_service_name_lookup_cache_service)
            .and_return(project_service_name_lookup_cache_service)

          expect(Costs::ReportResultsGeneratorService).to receive(:new)
            .with(
              billing_data_service,
              metrics_data_service,
              project_lookup_cache_service,
              project_service_name_lookup_cache_service
            )
            .and_return(generator_service)
          expect(generator_service).to receive(:report_results)
            .and_return(results)

          post :create, params: post_data
          expect(response).to be_success
          expect(CostsReport.count).to eq 1
          report = CostsReport.first
          expect(json_response).to eq({
            'id' => report.id,
            'year' => post_data[:year],
            'month' => post_data[:month],
            'billing_file' => post_data[:billing_file],
            'metrics_file' => post_data[:metrics_file],
            'notes' => post_data[:notes],
            'config' => post_data[:config],
            'results' => results,
            'created_at' => now_json_value,
            'published_at' => nil
          })
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable_type).to eq CostsReport.name
          expect(audit.auditable_id).to eq nil
          expect(audit.data).to eq({ 'id' => report.id })
          expect(audit.user).to eq current_user
        end

      end

      it_behaves_like 'a hub limited admin' do
        it 'should be forbidden' do
          post :create, params: post_data
          expect(response).to have_http_status(403)
        end
      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @report = create :costs_report
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @report.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          delete :destroy, params: { id: @report.id }
        end
      end

      it_behaves_like 'a hub admin' do

        def expect_deleted id
          expect(CostsReport.exists?(id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: id }
          expect(response).to be_success
          expect(CostsReport.exists?(id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.auditable_type).to eq CostsReport.name
          expect(audit.auditable_id).to eq nil
          expect(audit.data).to eq({ 'id' => id })
          expect(audit.user.id).to eq current_user_id
        end

        context 'for a non published report' do
          it 'should delete the specified report' do
            expect_deleted @report.id
          end
        end

        context 'for a published report' do
          before do
            @report.publish!
          end

          it 'should still be able to delete the specified report' do
            expect_deleted @report.id
          end
        end

      end

      it_behaves_like 'a hub limited admin' do
        it 'should be forbidden' do
          delete :destroy, params: { id: @report.id }
          expect(response).to have_http_status(403)
        end
      end

    end
  end

  describe 'POST #publish' do
    before do
      @report = create :costs_report
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :publish, params: { id: @report.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :publish, params: { id: @report.id }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should publish the specified report' do
          expect(CostsReport.exists?(@report.id)).to be true
          expect(Audit.count).to eq 0
          post :publish, params: { id: @report.id }
          expect(response).to be_success
          expect(json_response['published_at']).to eq now_json_value
          expect(CostsReport.exists?(@report.id)).to be true
          report = CostsReport.first
          expect(report.published_at.to_i).to eq now.to_i
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'publish'
          expect(audit.auditable_type).to eq CostsReport.name
          expect(audit.auditable_id).to eq nil
          expect(audit.data).to eq({ 'id' => report.id })
          expect(audit.user).to eq current_user
        end

      end

      it_behaves_like 'a hub limited admin' do
        it 'should be forbidden' do
          post :publish, params: { id: @report.id }
          expect(response).to have_http_status(403)
        end
      end

    end
  end

  describe 'POST #last_published_config' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :last_published_config
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :last_published_config
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when no costs reports have been published' do
          before do
            create :costs_report, published_at: nil
          end

          it 'should return an empty object' do
            get :last_published_config
            expect(json_response).to eq({})
          end
        end

        context 'when costs reports have been published' do
          let :config do
            { 'foo' => 'bar' }
          end

          before do
            create :costs_report, config: {}, published_at: nil
            move_time_to 1.minute.from_now
            create :costs_report, config: {}, published_at: now
            move_time_to 2.minute.from_now
            create :costs_report, config: config, published_at: now
            move_time_to 3.minute.from_now
            create :costs_report, config: {}, published_at: nil
          end

          it 'should return the last published config data' do
            get :last_published_config
            expect(json_response).to eq config
          end
        end

      end

    end
  end

end
