require 'rails_helper'

describe Kubernetes::ChangesetService, type: :service do
  include_context 'time helpers'

  before do
    @cluster = build :kubernetes_cluster
    @auditable = build :user_kubernetes_token, cluster: @cluster
  end

  describe '.get_events' do

    before do
      # last sync event
      create(:sync_kubernetes_tokens_audit, created_at: 1.day.ago, data: { cluster: @cluster.name })

      # kubernetes token related audit events
      create(:create_kubernetes_token_audit, created_at: 5.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
      create(:update_kubernetes_token_audit, created_at: 4.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
      create(:escalate_kubernetes_token_audit, created_at: 3.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
      create(:deescalate_kubernetes_token_audit, created_at: 2.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
      create(:destroy_kubernetes_token_audit, created_at: 1.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
    end

    it 'returns audit entries related to kubernetes tokens created since last sync event in descending order' do
      res = subject.get_events(@cluster.name)

      expect(res.count).to eq 5

      expect(res.first.action).to eq 'destroy'
      expect(res.first.created_at.to_s(:db)).to eq 1.hours.ago.to_s(:db)

      expect(res.second.action).to eq 'deescalate'
      expect(res.second.created_at.to_s(:db)).to eq 2.hours.ago.to_s(:db)

      expect(res.third.action).to eq 'escalate'
      expect(res.third.created_at.to_s(:db)).to eq 3.hours.ago.to_s(:db)

      expect(res.fourth.action).to eq 'update'
      expect(res.fourth.created_at.to_s(:db)).to eq 4.hours.ago.to_s(:db)

      expect(res.fifth.action).to eq 'create'
      expect(res.fifth.created_at.to_s(:db)).to eq 5.hours.ago.to_s(:db)
    end
  end

  describe 'private methods' do

    describe '.last_sync' do
      context 'never synced' do
        it 'defaults to 1 year ago' do
          expect(subject.send(:last_sync, @cluster.name)).to eq 1.year.ago.utc.to_s(:db)
        end
      end

      context 'synced before' do
        before do
          create(:sync_kubernetes_tokens_audit, created_at: 2.days.ago, data: { cluster: @cluster.name })
        end

        it 'returns time of last S3 sync for given cluster' do
          expect(subject.send(:last_sync, @cluster.name).to_s(:db)).to eq 2.days.ago.to_s(:db)
        end
      end
    end

    describe '.audit_entities_by_cluster' do
      let(:actions) { [ :create ] }

      before do
        create(:create_kubernetes_token_audit, created_at: 5.hours.ago, data: { cluster: @cluster.name })
        create(:create_kubernetes_token_audit, created_at: 10.hours.ago, data: { cluster: @cluster.name })
        create(:update_kubernetes_token_audit, created_at: 4.hours.ago, data: { cluster: @cluster.name })
      end

      it 'returns audit events for given cluster and actions in descending order' do
        res = subject.send(:audit_entities_by_cluster, @cluster.name, actions)

        expect(res.count).to eq 2

        expect(res.first.action).to eq 'create'
        expect(res.first.created_at.to_s(:db)).to eq 10.hours.ago.to_s(:db)

        expect(res.second.action).to eq 'create'
        expect(res.second.created_at.to_s(:db)).to eq 5.hours.ago.to_s(:db)
      end
    end

    describe '.audit_entities_by_cluster_and_auditable_type' do
      let(:auditable_type) { @auditable.class.name }
      let(:actions) { [ :update ] }

      before do
        create(:create_kubernetes_token_audit, created_at: 5.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
        create(:create_kubernetes_token_audit, created_at: 10.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
        create(:update_kubernetes_token_audit, created_at: 4.hours.ago, auditable: @auditable, data: { cluster: @cluster.name })
      end

      it 'returns audit events for given cluster, auditable object type and actions' do        
        res = subject.send(:audit_entities_by_cluster_and_auditable_type, @cluster.name, auditable_type, actions)

        expect(res.count).to eq 1

        expect(res.first.action).to eq 'update'
        expect(res.first.created_at.to_s(:db)).to eq 4.hours.ago.to_s(:db)
      end
    end
  end

end
