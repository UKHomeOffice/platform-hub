require 'rails_helper'

describe Kubernetes::ClusterLookupCacheService, type: :service do

  subject { Kubernetes::ClusterLookupCacheService.new }

  let!(:cluster_1) { create :kubernetes_cluster, name: 'name-foo', aliases: [] }
  let!(:cluster_2) { create :kubernetes_cluster, name: 'name-bar', aliases: ['alias-bar-1', 'alias-bar-2'] }
  let!(:cluster_3) { create :kubernetes_cluster, name: 'name-baz', aliases: ['alias-baz-1'] }

  context 'empty cache' do
    before do
      allow(KubernetesCluster).to receive(:by_name_or_alias).and_call_original
    end

    context 'non-existent cluster' do
      it 'should lookup from the database and return nil' do
        expect(subject.by_name_or_alias('name-does-not-exist')).to be nil
        expect(KubernetesCluster).to have_received(:by_name_or_alias)
      end
    end

    context 'existing cluster by name' do
      it 'should lookup from the database and return the cluster' do
        expect(subject.by_name_or_alias('name-foo')).to eq cluster_1
        expect(KubernetesCluster).to have_received(:by_name_or_alias)
      end
    end

    context 'existing cluster by alias' do
      it 'should lookup from the database and return the cluster' do
        expect(subject.by_name_or_alias('alias-bar-1')).to eq cluster_2
        expect(KubernetesCluster).to have_received(:by_name_or_alias)
      end
    end
  end

  context 'some items populated in cache' do
    before do
      subject.by_name_or_alias('name-foo')
      subject.by_name_or_alias('alias-bar-1')

      # Only spy after we've done the above
      allow(KubernetesCluster).to receive(:by_name_or_alias).and_call_original
    end

    context 'non-existent cluster' do
      it 'should lookup from the database and return nil' do
        expect(subject.by_name_or_alias('name-does-not-exist')).to be nil
        expect(KubernetesCluster).to have_received(:by_name_or_alias)
      end
    end

    context 'existing clusters' do
      context 'cache miss' do
        it 'should lookup from the database and return the cluster' do
          expect(subject.by_name_or_alias('name-baz')).to eq cluster_3
          expect(KubernetesCluster).to have_received(:by_name_or_alias)
        end
      end

      context 'cache hit for cluster 1 by name' do
        it 'should not lookup from the database and return the cluster' do
          expect(subject.by_name_or_alias('name-foo')).to eq cluster_1
          expect(KubernetesCluster).not_to have_received(:by_name_or_alias)
        end
      end

      context 'cache hits for cluster 2' do
        context 'by name' do
          it 'should not lookup from the database and return the cluster' do
            expect(subject.by_name_or_alias('name-bar')).to eq cluster_2
            expect(KubernetesCluster).not_to have_received(:by_name_or_alias)
          end
        end

        context 'by same alias as before' do
          it 'should not lookup from the database and return the cluster' do
            expect(subject.by_name_or_alias('alias-bar-1')).to eq cluster_2
            expect(KubernetesCluster).not_to have_received(:by_name_or_alias)
          end
        end

        context 'by other alias' do
          it 'should not lookup from the database and return the cluster' do
            expect(subject.by_name_or_alias('alias-bar-2')).to eq cluster_2
            expect(KubernetesCluster).not_to have_received(:by_name_or_alias)
          end
        end

        it 'should return the exact same instance from the cache' do
          a = subject.by_name_or_alias('name-bar')
          b = subject.by_name_or_alias('alias-bar-2')
          expect(a).to be b
          expect(KubernetesCluster).not_to have_received(:by_name_or_alias)
        end
      end
    end
  end

end
