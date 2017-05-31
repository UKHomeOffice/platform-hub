require 'rails_helper'

RSpec.describe ContactListsController, type: :controller do

  describe 'GET #show' do
    before do
      contact_list_hash_record = create :contact_list_hash_record
      @contact_list = ContactList.new contact_list_hash_record
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

        context 'for a specified contact list' do
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
    let :new_email_addresses do
      [ 'email1', 'email2' ]
    end

    let :put_params do
      {
        id: @contact_list.id,
        contact_list: {
          email_addresses: new_email_addresses
        }
      }
    end

    before do
      contact_list_hash_record = create :contact_list_hash_record
      @contact_list = ContactList.new contact_list_hash_record
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

        it 'updates the specified contact list' do
          expect(HashRecord.count).to eq 1
          expect(Audit.count).to eq 0
          put :update, params: put_params
          expect(response).to be_success
          expect(HashRecord.count).to eq 1
          updated = ContactList.find @contact_list.id
          expect(updated.email_addresses).to eq new_email_addresses
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'update_contact_list'
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
