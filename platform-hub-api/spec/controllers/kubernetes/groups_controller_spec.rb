require 'rails_helper'

RSpec.describe Kubernetes::GroupsController, type: :controller do

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :privileged
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          get :privileged
        end
      end

      it_behaves_like 'an admin' do
        let(:group_id) { 'some:group:id' }

        before do
          create(:kubernetes_groups_hash_record, data: [
            {
              id: group_id,
              privileged: true,
              description: 'some description'
            },
            {
              id: 'non-privileged-group',
              privileged: false,
              description: 'some description'
            },
          ])
        end

        it 'returns the list of cluster-wide privileged kubernetes groups' do
          get :privileged
          expect(response).to be_success

          expect(json_response.size).to eq 1

          group = json_response.first

          expect(group['id']).to eq group_id
          expect(group['privileged']).to eq true
        end

      end
    end
  end

end
