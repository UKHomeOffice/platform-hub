require 'rails_helper'

RSpec.describe DockerRepo, type: :model do

  describe '#name' do
    it { is_expected.to allow_value('foo').for(:name) }
    it { is_expected.to allow_value('foo-bar').for(:name) }
    it { is_expected.to allow_value('foo_bar').for(:name) }
    it { is_expected.to allow_value('foo/bar').for(:name) }
    it { is_expected.to allow_value('f1obar').for(:name) }
    it { is_expected.to allow_value('foo-bar5').for(:name) }
    it { is_expected.to allow_value('f123/bar').for(:name) }

    it { is_expected.not_to allow_value('foo bar').for(:name) }
    it { is_expected.not_to allow_value('1foo').for(:name) }
    it { is_expected.not_to allow_value('Foo').for(:name) }
    it { is_expected.not_to allow_value('fOO').for(:name) }
    it { is_expected.not_to allow_value('foo@bar').for(:name) }
    it { is_expected.not_to allow_value('foo£bar').for(:name) }
    it { is_expected.not_to allow_value('foo/#').for(:name) }
  end

  describe '#status' do
    before do
      @docker_repo = create :docker_repo, status: :pending
    end

    it 'allows updating the status' do
      @docker_repo.update! status: :active
      expect(@docker_repo.reload.status).to eq 'active'
    end
  end

  describe '#base_uri' do
    before do
      @docker_repo = create :docker_repo, base_uri: nil
    end

    it 'allows updating the base_uri' do
      @docker_repo.update! base_uri: 'http://example.org'
      expect(@docker_repo.reload.base_uri).to eq 'http://example.org'
    end
  end

  describe 'read-only attributes' do

    describe '#name' do
      before do
        @docker_repo = create :docker_repo, name: 'foo'
      end

      it 'is read-only' do
        previous_name = @docker_repo.name
        expect {
          @docker_repo.update! name: 'bar'
        }.to raise_error(
          ActiveRecord::ReadOnlyRecord,
          "name, service_id, provider can't be modified"
        )
        expect(@docker_repo.reload.name).to eq previous_name
      end
    end

    describe '#service_id' do
      before do
        service = create :service
        @docker_repo = create :docker_repo, service: service
      end

      it 'is read-only' do
        previous_service_id = @docker_repo.service_id
        expect {
          @docker_repo.update! service: create(:service)
        }.to raise_error(
          ActiveRecord::ReadOnlyRecord,
          "name, service_id, provider can't be modified"
        )
        expect(@docker_repo.reload.service_id).to eq previous_service_id
      end
    end

  end

  describe '#build_repo_name' do
    let(:project) { create :project, shortname: 'ABC' }
    let(:service) { create :service, project: project }

    before do
      @docker_repo = create(
        :docker_repo,
        name: 'foo',
        service: service
      )
    end

    it 'should add the project shortname to the name' do
      expect(@docker_repo.name).to eq 'abc/foo'
    end

    describe 'combined with uniquess check' do
      it 'should not allow the same repo name within the same project' do
        docker_repo_2 = build(
          :docker_repo,
          name: 'foo',
          service: service
        )

        expect(docker_repo_2).not_to be_valid
        expect(docker_repo_2.errors[:name].first).to eq "has already been taken"
      end

      it 'should allow differently named repos within the same project' do
        docker_repo_2 = build(
          :docker_repo,
          name: 'bar',
          service: service
        )

        expect(docker_repo_2).to be_valid
      end

      let(:other_project) { create :project, shortname: 'def' }

      it 'should allow a similarly named repo but on a different project' do
        other_docker_repo = build(
          :docker_repo,
          name: 'foo',
          service: create(:service, project: other_project)
        )

        expect(other_docker_repo).to be_valid
      end
    end
  end

end
