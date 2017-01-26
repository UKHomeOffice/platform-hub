require 'rails_helper'

RSpec.describe UsersController, type: :controller do

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

        context 'when only the authenticated user exists' do
          it 'should return a list with only the authenticated user' do
            get :index
            expect(response).to be_success
            expect(pluck_from_json_response('id')).to eq [current_user_id]
          end
        end

        context 'when multiple users exist' do
          before do
            @users = create_list :user, 3
          end

          let :total_users do
            @users.length + 1
          end

          let :all_user_ids do
            @users.map(&:id) + [current_user_id]
          end

          it 'should return a list of all the users' do
            # Remember, the currently authenticated user should also be in the list
            get :index
            expect(response).to be_success
            expect(json_response.length).to eq total_users
            expect(pluck_from_json_response('id')).to match_array all_user_ids
          end
        end

      end

    end
  end

  describe 'GET #show' do
    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        get :show, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :show, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        context 'for a non-existent user' do
          it 'should return a 404' do
            get :show, params: { id: 'foo' }
            expect(response).to have_http_status(404)
          end
        end

        context 'for a user that exists' do
          it 'should return the specified user resource' do
            get :show, params: { id: @user.id }
            expect(response).to be_success
            expect(json_response).to eq({
              'id' => @user.id,
              'name' => @user.name,
              'email' => @user.email,
              'role' => nil,
              'last_seen_at' => now_json_value,
              'identities' => []
            })
          end
        end

      end

    end
  end

  describe 'GET #search' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :search, params: { q: 'foo' }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :search, params: { q: 'foo' }
        end
      end

      it_behaves_like 'an admin' do

        context 'when no users exist' do
          it 'should not return any results' do
            get :search, params: { q: 'foo' }
            expect(response).to be_success
            expect(json_response.length).to eq 0
          end
        end

        context 'when users exist' do
          before do
            create_list :user, 3
            @user = create :user, name: 'foobar'
          end

          it 'should return expected results' do
            get :search, params: { q: 'foo' }
            expect(response).to be_success
            expect(json_response.length).to eq 1
            expect(json_response.first['id']).to eq @user.id
          end
        end

      end

    end
  end

  describe 'POST #make_admin' do
    before do
      @user = create :user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :make_admin, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :make_admin, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should make the specified user an admin' do
          expect(@user.admin?).to be false
          get :make_admin, params: { id: @user.id }
          expect(response).to be_success
          expect(@user.reload.admin?).to be true
        end

      end

    end
  end

  describe 'POST #revoke_admin' do
    before do
      @user = create :admin_user
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        post :revoke_admin, params: { id: @user.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :revoke_admin, params: { id: @user.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should revoke the admin role for the specified user' do
          expect(@user.admin?).to be true
          get :revoke_admin, params: { id: @user.id }
          expect(response).to be_success
          expect(@user.reload.admin?).to be false
        end

      end

    end
  end

end
