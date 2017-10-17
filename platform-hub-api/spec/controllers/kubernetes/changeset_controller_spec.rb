require 'rails_helper'

RSpec.describe Kubernetes::ChangesetController, type: :controller do
  include_context 'time helpers'

  before do
    @cluster = build :kubernetes_cluster
  end

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index, params: { cluster: @cluster.name }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden' do
        before do
          get :index, params: { cluster: @cluster.name }
        end
      end

      it_behaves_like 'an admin' do

        before do
          auditable = build :user_kubernetes_token, cluster: @cluster

          create(:sync_kubernetes_tokens_audit, created_at: 1.day.ago, data: { cluster: @cluster.name })
          create(:create_kubernetes_token_audit, created_at: 5.hours.ago, auditable: auditable, data: { cluster: @cluster.name })
          create(:update_kubernetes_token_audit, created_at: 4.hours.ago, auditable: auditable, data: { cluster: @cluster.name })
        end

        it 'presents audit entries related to kubernetes tokens changes since last sync event in descending order' do
          get :index, params: { cluster: @cluster.name }

          expect(response).to be_success
          expect(json_response.count).to eq 2

          expect(json_response.first['action']).to eq 'update'
          expect(Time.parse(json_response.first['created_at']).to_s(:db)).to eq 4.hours.ago.to_s(:db)

          expect(json_response.second['action']).to eq 'create'
          expect(Time.parse(json_response.second['created_at']).to_s(:db)).to eq 5.hours.ago.to_s(:db)
        end

      end
    end
  end

  describe 'private methods' do

    describe '#load_audits' do
      before do
        allow(controller).to receive(:params).and_return({cluster: @cluster.name})
      end

      it 'loads kubernetes token audits' do
        expect(Kubernetes::ChangesetService).to receive(:get_events).with(@cluster.name)

        controller.send(:load_audits)

        expect(assigns(:audits))
      end
    end
  end
end
