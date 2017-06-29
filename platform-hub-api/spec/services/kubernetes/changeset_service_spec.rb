require 'rails_helper'

describe Kubernetes::ChangesetService, type: :service do

  describe '.get_events' do
    let(:criteria) { double(:criteria) }
    let(:cluster) { 'development' }
    let(:last_sync_date) { 2.days.ago }
    let(:changeset) { [ double ] }

    it 'builds criteria fetching kubernetes tokens related audit events since which occured since given time' do
      expect(subject).to receive(:audit_entities)
        .with(Kubernetes::ChangesetService::CHANGSET_ACTIONS, cluster) { criteria }
      expect(criteria).to receive(:where).with("created_at > ?", last_sync_date) { changeset }

      subject.get_events(cluster, last_sync_date)
    end
  end

  describe '.last_sync' do
    let(:criteria) { double(:criteria) }
    let(:cluster) { 'development' }

    context 'never synced' do
      before do
        expect(subject).to receive(:audit_entities).with(:sync_kubernetes_tokens, cluster) { criteria }
        expect(criteria).to receive(:first) { nil }
      end

      it 'defaults to 1 year ago' do
        expect(subject.last_sync(cluster)).to eq 1.year.ago.utc.to_s(:db)
      end
    end

    context 'synced before' do
      let(:last_sync_date) { 2.days.ago }

      before do
        expect(subject).to receive(:audit_entities).with(:sync_kubernetes_tokens, cluster) { criteria }
        expect(criteria).to receive(:first) { criteria }
        expect(criteria).to receive(:try).with(:created_at) { last_sync_date }
      end

      it 'returns time of last S3 sync for given cluster' do
        expect(subject.last_sync(cluster)).to eq last_sync_date
      end
    end
  end

  describe 'private methods' do
    describe '.audit_entities' do
      let(:criteria) { double(:criteria) }
      let(:actions) { [:sync_kubernetes_tokens] }
      let(:cluster) { 'development' }

      it 'builds criteria fetching audit events for given cluster and event type' do
        expect(Audit).to receive(:by_action).with(actions) { criteria }
        expect(criteria).to receive(:where).with("data->>'cluster' = ?", cluster) { criteria }
        expect(criteria).to receive(:order).with(id: :desc) 
        
        subject.send(:audit_entities, actions, cluster)
      end
    end
  end

end
