require 'rails_helper'

RSpec.describe ContactListsController, type: :controller do

  include_context 'time helpers'

  describe 'GET #index' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :index
        end
      end

      it_behaves_like 'an admin' do

        before do
          @contact_lists = create_list :contact_list, 3
        end

        let :total_contact_lists do
          @contact_lists.length
        end

        let :contact_list_ids do
          @contact_lists.map(&:id)
        end

        it 'should return a list of all contact lists' do
          get :index
          expect(response).to be_success
          expect(json_response.length).to eq total_contact_lists
          expect(pluck_from_json_response('id')).to match_array contact_list_ids
        end

      end

    end
  end


  describe 'GET #show' do
    before do
      @contact_list = create :contact_list
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @contact_list.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :show, params: { id: @contact_list.id }
        end
      end

      it_behaves_like 'an admin' do

        context 'for a non-existent contact list' do
          it 'should return a 404' do
            get :show, params: { id: 'unknown' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a contact list that exists' do
          it 'should return the specified contact list resource' do
            get :show, params: { id: @contact_list.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @contact_list.id,
              'email_addresses' => @contact_list.email_addresses
            })
          end
        end

      end

    end
  end

  describe 'PUT #update' do
    let(:id) { 'foo' }
    let :email_addresses do
      [ 'email1', 'email2' ]
    end

    let :put_params do
      {
        id: id,
        contact_list: {
          email_addresses: email_addresses
        }
      }
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        put :update, params: put_params
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          put :update, params: put_params
        end
      end

      it_behaves_like 'an admin' do
        context 'for a contact list that doesn\'t yet exist' do
          it 'should create a new contact list with the ID specified' do
            expect(ContactList.count).to eq 0
            expect(Audit.count).to eq 0
            put :update, params: put_params
            expect(response).to be_success
            expect(ContactList.count).to eq 1
            cl = ContactList.find id
            expect(cl.email_addresses).to eq email_addresses
            expect(Audit.count).to eq 1
            audit = Audit.last
            expect(audit.action).to eq 'update_contact_list'
            expect(audit.user.id).to eq current_user_id
          end
        end

        context 'for an existing contact list' do
          before do
            @contact_list = create :contact_list, id: id
          end

          it 'should update it as expected' do
            expect(ContactList.exists?(@contact_list.id)).to be true
            expect(Audit.count).to eq 0
            put :update, params: put_params
            expect(response).to be_success
            expect(ContactList.count).to be 1
            cl = ContactList.find id
            expect(cl.email_addresses).to eq email_addresses
            expect(Audit.count).to eq 1
            audit = Audit.last
            expect(audit.action).to eq 'update_contact_list'
            expect(audit.user.id).to eq current_user_id
          end
        end

      end

    end
  end

  describe 'DELETE #destroy' do
    before do
      @contact_list = create :contact_list
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @contact_list.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @contact_list.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should delete the specified contact list' do
          expect(ContactList.exists?(@contact_list.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @contact_list.id }
          expect(response).to be_success
          expect(ContactList.exists?(@contact_list.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy_contact_list'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
