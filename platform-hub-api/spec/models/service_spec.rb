require 'rails_helper'

RSpec.describe Service, type: :model do

  describe 'when destroyed' do
    subject { create :service }

    context 'and has namespace(s)' do
      let(:cluster) { create :kubernetes_cluster, allocate_to: subject.project }
      let!(:n1) { create :kubernetes_namespace, service: subject, cluster: cluster }
      let!(:n2) { create :kubernetes_namespace }

      it 'deletes associated namespaces from the database too' do
        expect(KubernetesNamespace.exists?(id: n1.id)).to be true
        expect(KubernetesNamespace.exists?(id: n2.id)).to be true

        subject.destroy

        expect(KubernetesNamespace.exists?(id: n1.id)).to be false
        expect(KubernetesNamespace.exists?(id: n2.id)).to be true
      end
    end
  end

end
