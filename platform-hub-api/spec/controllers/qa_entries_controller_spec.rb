require 'rails_helper'

RSpec.describe QaEntriesController, type: :controller do

  include_context 'time helpers'
  include_context 'help search helpers'

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
          @qa_entries = create_list :qa_entry, 3
        end

        let :total_qa_entries do
          @qa_entries.length
        end

        let :qa_entry_ids do
          @qa_entries.sort_by(&:question).map(&:id)
        end

        it 'should return a list of all Q&A entries' do
          get :index
          expect(response).to be_success
          expect(json_response.length).to eq total_qa_entries
          expect(pluck_from_json_response('id')).to eq qa_entry_ids
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @qa_entry = create :qa_entry
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @qa_entry.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          get :show, params: { id: @qa_entry.id }
        end
      end

      it_behaves_like 'a hub admin' do

        context 'for a non-existent Q&A entry' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a Q&A entry that exists' do
          it 'should return the specified Q&A entry resource' do
            get :show, params: { id: @qa_entry.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @qa_entry.id,
              'question' => @qa_entry.question,
              'answer' => @qa_entry.answer,
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
      source_data = build :qa_entry

      {
        qa_entry: {
          question: source_data.question,
          answer: source_data.answer
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

        before do
          expect(help_search_service_instance).to receive(:index_item)
            .with(QaEntry)
        end

        it 'creates a new Q&A entry as expected' do
          expect(QaEntry.count).to eq 0
          expect(Audit.count).to eq 0
          post :create, params: post_data
          expect(response).to be_success
          expect(QaEntry.count).to eq 1
          qa_entry = QaEntry.first
          expect(json_response).to eq({
            'id' => qa_entry.id,
            'question' => post_data[:qa_entry][:question],
            'answer' => post_data[:qa_entry][:answer],
            'created_at' => now_json_value,
            'updated_at' => now_json_value
          });
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'create'
          expect(audit.auditable.id).to eq qa_entry.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'PUT #update' do
    let :put_data do
      {
        id: @qa_entry.id,
        qa_entry: {
          answer: 'NEW answer - so much better now!'
        }
      }
    end

    before do
      @qa_entry = create :qa_entry
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
          expect(help_search_service_instance).to receive(:index_item)
            .with(@qa_entry)
        end

        it 'updates the specified Q&A entry' do
          expect(QaEntry.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_data
          expect(response).to be_success
          expect(QaEntry.count).to eq 1
          updated = QaEntry.first
          expect(updated.question).to eq @qa_entry.question
          expect(updated.answer).to eq put_data[:qa_entry][:answer]
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update'
          expect(audit.auditable.id).to eq @qa_entry.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @qa_entry = create :qa_entry
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @qa_entry.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not a hub admin so forbidden'  do
        before do
          delete :destroy, params: { id: @qa_entry.id }
        end
      end

      it_behaves_like 'a hub admin' do

        before do
          expect(help_search_service_instance).to receive(:delete_item)
            .with(@qa_entry)
        end

        it 'should delete the specified Q&A entry' do
          expect(QaEntry.exists?(@qa_entry.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @qa_entry.id }
          expect(response).to be_success
          expect(QaEntry.exists?(@qa_entry.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
