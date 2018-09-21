require 'rails_helper'

RSpec.describe PinnedHelpEntriesController, type: :controller do

  let(:key) { 'pinned_help_entries' }

  describe 'GET #show' do
    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show
        end
      end

      it_behaves_like 'a hub admin' do

        context 'when no data exists' do
          it 'creates a new HashRecord with an empty default list and returns it' do
            expect(HashRecord.webapp.where(id: key).count).to eq 0
            get :show
            expect(response).to be_success
            expect(json_response).to eq([])
            expect(HashRecord.webapp.where(id: key).count).to eq 1
          end
        end

        context 'when data exists' do
          let :data do
            {
              'default' => ['1', '2', '3']
            }
          end

          before do
            @pinned_help_entries = create :hash_record, id: key, scope: 'webapp', data: data
          end

          it 'returns the default list' do
            get :show
            expect(response).to be_success
            expect(json_response).to eq data['default']
          end
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        'pinned_help_entry' => { '_json' => ['1', '5', '4', '7'] }
      }
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

        before do
          @pinned_help_entries = create :hash_record, id: key, scope: 'webapp', data: { 'default'=> ['1', '2', '3'] }
        end

        it 'updates the default list' do
          expect(HashRecord.webapp.where(id: key).count).to eq 1
          put :update, params: put_data
          expect(response).to be_success
          expect(json_response).to eq put_data['pinned_help_entry']['_json']
          expect(HashRecord.webapp.where(id: key).count).to eq 1
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update_pinned_help_entries'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
