require 'rails_helper'

RSpec.describe DocsSourcesController, type: :controller do

  include_context 'time helpers'

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

        before do
          @docs_sources = create_list :docs_source, 3
        end

        let :total_docs_sources do
          @docs_sources.length
        end

        let :docs_source_ids do
          @docs_sources.sort_by(&:name).map(&:id)
        end

        it 'should return a list of all docs sources' do
          get :index
          expect(response).to be_success
          expect(json_response.length).to eq total_docs_sources
          expect(pluck_from_json_response('id')).to eq docs_source_ids
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @docs_source = create :docs_source
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @docs_source.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show, params: { id: @docs_source.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent docs source' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a docs source that exists' do
          it 'should return the specified docs source resource' do
            get :show, params: { id: @docs_source.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @docs_source.id,
              'kind' => @docs_source.kind,
              'name' => @docs_source.name,
              'config' => Hashie::Mash.new(@docs_source.config),
              'is_fetching' => @docs_source.is_fetching,
              'last_fetch_status' => @docs_source.last_fetch_status,
              'last_fetch_started_at' => @docs_source.last_fetch_started_at,
              'last_fetch_error' => @docs_source.last_fetch_error,
              'last_successful_fetch_started_at' => @docs_source.last_successful_fetch_started_at,
              'last_successful_fetch_metadata' => @docs_source.last_successful_fetch_metadata,
              'created_at' => now_json_value,
              'updated_at' => now_json_value,
            })
          end
        end

      end

    end
  end

  describe 'POST #create' do
    let :post_data do
      source_data = build :docs_source

      {
        docs_source: {
          kind: source_data.kind,
          name: source_data.name,
          config: source_data.config
        }
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

        it 'creates a new docs source as expected' do
          expect(DocsSource.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(DocsSource.count).to eq 1
          docs_source = DocsSource.first
          expect(json_response).to eq({
            'id' => docs_source.id,
            'kind' => post_data[:docs_source][:kind],
            'name' => post_data[:docs_source][:name],
            'config' => Hashie::Mash.new(post_data[:docs_source][:config]),
            'is_fetching' => docs_source.is_fetching,
            'last_fetch_status' => docs_source.last_fetch_status,
            'last_fetch_started_at' => docs_source.last_fetch_started_at,
            'last_fetch_error' => docs_source.last_fetch_error,
            'last_successful_fetch_started_at' => docs_source.last_successful_fetch_started_at,
            'last_successful_fetch_metadata' => docs_source.last_successful_fetch_metadata,
            'created_at' => now_json_value,
            'updated_at' => now_json_value,
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq docs_source.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @docs_source.id,
        docs_source: {
          name: 'new name'
        }
      }
    end

    before do
      @docs_source = create :docs_source
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: put_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          put :update, params: put_data
        end
      end

      it_behaves_like 'a hub admin' do

        it 'updates the specified docs source' do
          expect(DocsSource.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(DocsSource.count).to eq 1
          updated = DocsSource.first
          expect(updated.name).to eq put_data[:docs_source][:name]
          expect(updated.config).to eq Hashie::Mash.new(@docs_source.config)
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @docs_source.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    let(:help_search_service) { instance_double('HelpSearchService') }

    before do
      allow(HelpSearchService).to receive(:instance).and_return(help_search_service)

      @docs_source = create :docs_source
      create_list :docs_source_entry, 3, docs_source: @docs_source
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @docs_source.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          delete :destroy, params: { id: @docs_source.id }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should delete the specified docs source and it\'s entries' do
          expect(DocsSource.exists?(@docs_source.id)).to be true
          expect(DocsSourceEntry.count).to be 3
          expect(Audit.count).to eq 0
          expect(help_search_service).to receive(:delete_item).exactly(3).times
          delete :destroy, params: { id: @docs_source.id }
          expect(response).to be_success
          expect(DocsSource.exists?(@docs_source.id)).to be false
          expect(DocsSourceEntry.count).to be 0
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'POST #sync_all' do

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :sync_all
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :sync_all
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should schedule a docs sync job' do
          expect(DocsSyncJob).to receive(:perform_later)
          post :sync_all
          expect(response).to be_success
        end

      end

    end
  end

  describe 'POST #sync' do
    before do
      @docs_source = create :docs_source
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :sync, params: { id: @docs_source.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          post :sync, params: { id: @docs_source.id }
        end
      end

      it_behaves_like 'a hub admin' do

        it 'should schedule a docs sync job for the docs_source' do
          expect(DocsSyncJob).to receive(:perform_later).with(@docs_source)
          post :sync, params: { id: @docs_source.id }
          expect(response).to be_success
        end

      end

    end
  end

end
