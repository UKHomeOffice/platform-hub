require 'rails_helper'

describe Kubernetes::NamespaceLookupCacheService, type: :service do

  subject { Kubernetes::NamespaceLookupCacheService.new }

  let!(:service) { create :service }
  let!(:cluster) { create :kubernetes_cluster, allocate_to: service.project }
  let!(:namespace) { create :kubernetes_namespace, service: service, cluster: cluster }

  before do
    subject.by_cluster_and_name(cluster, namespace.name)

    # Only spy after we've done the above
    allow(KubernetesNamespace).to receive(:by_cluster).and_call_original
  end

  it 'should retrieve the namespace from the cache' do
    a = subject.by_cluster_and_name(cluster, namespace.name)
    b = subject.by_cluster_and_name(cluster, namespace.name)

    expect(KubernetesNamespace).not_to have_received(:by_cluster)

    # Make sure these are the same instances in memory
    expect(a).to be b
  end

end
