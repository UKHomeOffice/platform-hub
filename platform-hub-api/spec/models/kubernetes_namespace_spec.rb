require 'rails_helper'

RSpec.describe KubernetesNamespace, type: :model do

  describe '#name' do
    it { is_expected.to allow_value('f').for(:name) }
    it { is_expected.to allow_value('foo').for(:name) }
    it { is_expected.to allow_value('foo-bar').for(:name) }
    it { is_expected.to allow_value('foo-1').for(:name) }
    it { is_expected.to allow_value('1').for(:name) }
    it { is_expected.to allow_value('1-foo').for(:name) }

    it { is_expected.not_to allow_value('foo_bar').for(:name) }
    it { is_expected.not_to allow_value('foo_1').for(:name) }
    it { is_expected.not_to allow_value('foo bar').for(:name) }
    it { is_expected.not_to allow_value('foo 1').for(:name) }
    it { is_expected.not_to allow_value('-foo').for(:name) }
    it { is_expected.not_to allow_value('foo-').for(:name) }
    it { is_expected.not_to allow_value('_foo').for(:name) }

    context 'for an existing namespace' do
      subject { create :kubernetes_namespace }

      it 'should only allow unique names per cluster' do
        expect { create :kubernetes_namespace, name: subject.name, service: subject.service, cluster: subject.cluster }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Name already exists for the cluster"
        )
      end
    end
  end

  describe 'custom validations' do

    describe '#allowed_clusters_only' do
      let!(:service) { create :service }
      let!(:allocated_cluster) { create :kubernetes_cluster, allocate_to: service.project }
      let!(:unallocated_cluster) { create :kubernetes_cluster }
      let!(:other_allocated_cluster) { create :kubernetes_cluster, allocate_to: create(:project) }

      it 'allows using the allocated cluster' do
        namespace = build :kubernetes_namespace, service: service, cluster: allocated_cluster
        expect(namespace).to be_valid
      end

      it 'raises error when using unallocated cluster' do
        expect { create :kubernetes_namespace, service: service, cluster: unallocated_cluster }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Cluster is not allowed for this namespace"
        )
      end

      it 'raises error when using other allocated cluster' do
        expect { create :kubernetes_namespace, service: service, cluster: other_allocated_cluster }.to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Cluster is not allowed for this namespace"
        )
      end
    end

  end

end
