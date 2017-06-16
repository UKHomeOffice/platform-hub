require 'rails_helper'

RSpec.describe Kubernetes::ChangesetController, type: :controller do

  include_context 'time helpers'

  let(:cluster) { 'development' }

  describe 'GET #index' do

    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :index, params: { cluster: cluster }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden' do
        before do
          get :index, params: { cluster: cluster }
        end
      end

      it_behaves_like 'an admin' do

        before do
          create(:sync_kubernetes_tokens_audit, created_at: 1.day.ago, data: { cluster: cluster})
          create(:update_kubernetes_identity_audit, created_at: 1.hours.ago, data: { cluster: cluster})
          create(:revoke_kubernetes_token_audit, created_at: 2.hours.ago, data: { cluster: cluster})
          create(:claim_kubernetes_token_audit, created_at: 3.hours.ago, data: { cluster: cluster})
          create(:claim_kubernetes_token_audit, created_at: 2.days.ago, data: { cluster: cluster})
        end

        it 'presents audit entries related to kubernetes tokens changes since last sync event in descending order' do
          get :index, params: { cluster: cluster }

          expect(response).to be_success
          expect(json_response.count).to be 3

          expect(json_response.first['action']).to eq 'claim_kubernetes_token'
          expect(Time.parse(json_response.first['created_at']).to_s(:db)).to eq 3.hours.ago.to_s(:db)

          expect(json_response.second['action']).to eq 'revoke_kubernetes_token'
          expect(Time.parse(json_response.second['created_at']).to_s(:db)).to eq 2.hours.ago.to_s(:db)

          expect(json_response.third['action']).to eq 'update_kubernetes_identity'
          expect(Time.parse(json_response.third['created_at']).to_s(:db)).to eq 1.hours.ago.to_s(:db)
        end

      end
    end
  end

  describe 'private methods' do

    describe '#load_changeset' do
      let(:last_sync_date) { 2.days.ago }
      let(:cluster) { 'development' }
      let(:changeset) { [ double ] }

      before do
        allow(controller).to receive(:params).and_return({cluster: cluster})
      end

      it 'loads kubernetes tokens changeset' do
        expect(Kubernetes::ChangesetService).to receive(:last_sync).with(cluster) { last_sync_date }
        expect(Kubernetes::ChangesetService).to receive(:get_events).with(cluster, last_sync_date) { changeset }

        controller.send(:load_changeset)

        expect(assigns(:changeset)).to eq changeset
      end
    end
  end
end
