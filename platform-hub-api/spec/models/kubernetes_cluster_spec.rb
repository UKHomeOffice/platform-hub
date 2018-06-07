require 'rails_helper'

RSpec.describe KubernetesCluster, type: :model do

  describe 'scopes' do

    describe 'by_alias' do
      let(:value) { 'foo' }

      subject { KubernetesCluster.by_alias(value) }

      context 'when no aliases are set' do
        let!(:cluster) { create :kubernetes_cluster, aliases: [] }

        it 'should not find any clusters' do
          expect(subject.count).to be 0
        end
      end

      context 'when the value is set in an aliases list' do
        let!(:cluster) { create :kubernetes_cluster, aliases: [ value, 'another' ] }

        it 'should find the cluster' do
          expect(subject.entries).to eq [ cluster ]
        end
      end

      context 'when the value is not used' do
        let!(:cluster) { create :kubernetes_cluster, aliases: [ 'another' ] }

        it 'should not find any clusters' do
          expect(subject.count).to be 0
        end
      end
    end

    describe 'by_name_or_alias' do
      let(:value) { 'foo' }

      subject { KubernetesCluster.by_name_or_alias(value) }

      context 'when the value is set as a name' do
        let!(:cluster) { create :kubernetes_cluster, name: value, aliases: [ 'another' ] }

        it 'should find by name' do
          expect(subject.entries).to eq [ cluster ]
        end
      end

      context 'when the value is set as a name' do
        let!(:cluster) { create :kubernetes_cluster, name: 'different-name', aliases: [ value, 'another' ] }

        it 'should find by alias' do
          expect(subject.entries).to eq [ cluster ]
        end
      end

      context 'when the value is not used' do
        let!(:cluster) { create :kubernetes_cluster, name: 'different-name', aliases: [ 'another' ] }

        it 'should not match if the value isn\'t used' do
          expect(subject.count).to be 0
        end
      end
    end

  end

  describe '#name' do
    it { is_expected.to allow_value('f').for(:name) }
    it { is_expected.to allow_value('foo').for(:name) }
    it { is_expected.to allow_value('foo_bar').for(:name) }
    it { is_expected.to allow_value('foo-bar').for(:name) }
    it { is_expected.to allow_value('foo-1').for(:name) }
    it { is_expected.to allow_value('foo_1').for(:name) }

    it { is_expected.not_to allow_value('foo bar').for(:name) }
    it { is_expected.not_to allow_value('foo 1').for(:name) }
    it { is_expected.not_to allow_value('1-foo').for(:name) }
    it { is_expected.not_to allow_value('1').for(:name) }
    it { is_expected.not_to allow_value('-foo').for(:name) }
    it { is_expected.not_to allow_value('_foo').for(:name) }
  end

  describe '#aws_account_id' do
    it { is_expected.to allow_value('123456789012').for(:aws_account_id) }
    it { is_expected.to allow_value(nil).for(:aws_account_id) }
    it { is_expected.to allow_value('').for(:aws_account_id) }

    it { is_expected.not_to allow_value('123').for(:aws_account_id) }
    it { is_expected.not_to allow_value('1234567890').for(:aws_account_id) }
    it { is_expected.not_to allow_value('1234567890123').for(:aws_account_id) }
    it { is_expected.not_to allow_value('A12345678901').for(:aws_account_id) }
    it { is_expected.not_to allow_value('A').for(:aws_account_id) }
  end

  describe '#aliases' do

    context 'process_aliases before save' do
      context 'for a new record' do
        it 'processes the values as expected before saving' do
          c = build :kubernetes_cluster, aliases: [ 'Foo', 'bar', 'foo', nil, 'baz', 'bar', nil ]
          c.save!
          expect(c.aliases).to eq [ 'bar', 'baz', 'foo' ]
        end
      end

      context 'for an existing record' do
        it 'processes the values as expected before saving' do
          c = create :kubernetes_cluster, aliases: [ 'foo', 'bar' ]
          c.save!
          c_again = KubernetesCluster.find c.id
          c_again.aliases << 'Bar'
          c_again.aliases << 'baz'
          c_again.save!
          expect(c_again.aliases).to eq [ 'bar', 'baz', 'foo' ]
        end
      end
    end

    context 'uniqueness' do
      let(:existing_cluster_name) { 'cluster2' }
      let(:existing_alias) { 'foo' }

      before do
        create :kubernetes_cluster, name: 'cluster1', aliases: [ existing_alias, 'bar' ]
        create :kubernetes_cluster, name: existing_cluster_name, aliases: [ 'baz', 'non' ]
      end

      let :validation_error_message do
        'contains a value that is already being used as the name, or an alias, of an existing cluster'
      end

      context 'for a new record' do
        it 'ensures an alias cannot be reused across clusters' do
          c = build :kubernetes_cluster, name: 'cluster3', aliases: [ existing_alias ]
          expect(c.valid?).to be false
          expect(c.errors[:aliases]).to include(validation_error_message)
        end

        it 'ensures an alias cannot be the same as a name that is already being used' do
          c = build :kubernetes_cluster, name: 'cluster3', aliases: [ existing_cluster_name ]
          expect(c.valid?).to be false
          expect(c.errors[:aliases]).to include(validation_error_message)
        end
      end

      context 'for an existing record' do
        let(:cluster) { KubernetesCluster.find_by(name: existing_cluster_name) }

        it 'ensures an alias cannot be reused across clusters' do
          cluster.aliases << existing_alias
          expect(cluster.valid?).to be false
          expect(cluster.errors[:aliases]).to include(validation_error_message)
        end

        it 'ensures an alias cannot be the same as a name that is already being used' do
          cluster.aliases << existing_cluster_name
          expect(cluster.valid?).to be false
          expect(cluster.errors[:aliases]).to include(validation_error_message)
        end

        it 'can still update an existing cluster with a new alias as expected' do
          cluster.aliases << 'new'
          expect(cluster.valid?).to be true
          expect(cluster.save).to be true
        end
      end
    end

  end

  describe 'when destroyed' do
    subject { create :kubernetes_cluster }

    context 'and has namespace(s)' do
      let :service do
        s = create :service
        create :allocation, allocatable: subject, allocation_receivable: s.project
        s
      end
      let!(:n1) { create :kubernetes_namespace, service: service, cluster: subject }
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
