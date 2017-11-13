require 'rails_helper'

RSpec.describe AppSettingsController, type: :controller do

  let(:key) { 'app_settings' }

  describe 'GET #show' do
    let(:public_field_key) { 'public_field' }
    let(:private_field_key) { 'private_field' }

    before do
      stub_const('AppSettingsController::PUBLIC_FIELDS', [public_field_key])
    end

    context 'when no app settings exist' do
      it 'creates an empty app settings under the hood and returns it' do
        expect(HashRecord.webapp.where(id: key).count).to eq 0
        get :show
        expect(response).to be_success
        expect(json_response).to eq({})
        expect(HashRecord.webapp.where(id: key).count).to eq 1
      end
    end

    context 'when app settings already exist' do
      let :data do
        {
          public_field_key => 'foo',
          private_field_key => 'bar'
        }
      end

      before do
        @app_settings = create :hash_record, id: key, scope: 'webapp', data: data
      end

      context 'when not authenticated' do
        it 'only returns the public fields' do
          get :show
          expect(response).to be_success
          expect(json_response).to eq({
            public_field_key => 'foo'
          })
        end
      end

      it_behaves_like 'authenticated' do
        it 'returns all the fields' do
          get :show
          expect(response).to be_success
          expect(json_response).to eq data
        end
      end
    end
  end

  describe 'PUT #update' do
    let :put_data do
      { 'foo' => 'bar' }
    end

    before do
      @app_settings = create :hash_record, id: key, scope: 'webapp', data: {}
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: put_data
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :update, params: put_data
        end
      end

      it_behaves_like 'an admin' do
        it 'allows updating of the whole app settings data' do
          expect(HashRecord.webapp.where(id: key).count).to eq 1
          put :update, params: put_data
          expect(response).to be_success
          expect(json_response).to eq put_data
          expect(HashRecord.webapp.where(id: key).count).to eq 1
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update_app_settings'
          expect(audit.user.id).to eq current_user_id
        end
      end

    end
  end

end
