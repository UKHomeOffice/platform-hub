require 'rails_helper'

RSpec.describe Kubernetes::ClustersController, type: :controller do

  let(:key) { 'clusters' }

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          post :index
        end
      end

      it_behaves_like 'an admin' do

        context 'when no kubernetes clusters exist' do
          it 'creates an empty kubernetes clusters under the hood and returns it' do
            expect(HashRecord.kubernetes.where(id: key).count).to eq 0
            get :index
            expect(response).to be_success
            expect(json_response).to eq([])
            expect(HashRecord.kubernetes.where(id: key).count).to eq 1
          end
        end

        context 'when kubernetes clusters already exist' do
          let :data do
            [
              { 'id' => 'foo', 'description' => 'Foo cluster' },
              { 'id' => 'bar', 'description' => 'Bar cluster' },
              { 'id' => 'baz', 'description' => 'Baz cluster' },
            ]
          end

          before do
            @kubernetes_clusters = create :hash_record, id: key, scope: 'kubernetes', data: data
          end

          it 'returns the existing kubernetes clusters data' do
            get :index
            expect(response).to be_success
            expect(json_response).to eq data
          end
        end

      end
    end
  end
end
