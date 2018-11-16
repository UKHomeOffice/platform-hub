require 'rails_helper'

describe DockerRepoLifecycleService, type: :service do

  subject do
    DockerRepoLifecycleService.new
  end

  let(:user) { create :user }
  let(:audit_context) { { user: user } }

  describe '#request_create' do

    let(:service) { create :service }

    let :params do
      {
        name: 'foo',
        description: 'so much fooooo'
      }
    end

    it 'should create a new repo, post a request message to the queue and log an audit' do
      expect(DockerRepo.count).to eq 0
      expect(Audit.count).to eq 0

      docker_repo = subject.request_create service, params, audit_context

      expect(DockerRepo.count).to eq 1
      expect(docker_repo.service).to eq service
      expect(docker_repo.name).to end_with params[:name]
      expect(docker_repo.description).to eq params[:description]
      expect(docker_repo.provider).to eq DockerRepo.providers[:ECR]
      expect(docker_repo.url).to be nil
      expect(docker_repo.status).to eq DockerRepo.statuses[:pending]

      expect(Audit.count).to be 1
      audit = Audit.first
      expect(audit.action).to eq 'request_create'
      expect(audit.associated).to eq service
      expect(audit.auditable).to eq docker_repo
      expect(audit.user).to eq user
    end
  end

  describe '#request_delete!' do

    let(:docker_repo) { create :docker_repo }

    it 'should mark the repo for deletion, post a request message to the queue and log an audit' do
      expect(Audit.count).to eq 0

      subject.request_delete! docker_repo, audit_context

      expect(DockerRepo.exists?(docker_repo.id)).to be true
      expect(DockerRepo.find(docker_repo.id)).to be_deleting

      expect(Audit.count).to eq 1
      audit = Audit.first
      expect(audit.action).to eq 'request_delete'
      expect(audit.auditable).to eq docker_repo
      expect(audit.user).to eq user
    end
  end

  shared_examples 'common message handling' do |action|
    let :message do
      {
        'resource' => {
          'id' => repo_id,
          'name' => repo_name,
          'url' => 'a_url'
        },
        'result' => {
          'status' => result_status
        }
      }
    end

    let!(:docker_repo) { create :docker_repo }

    let(:repo_id) { docker_repo.id }
    let(:repo_name) { docker_repo.name }

    let(:result_status) { 'Complete' }

    it 'should log an audit for the message' do
      expect(Audit.count).to eq 0

      subject.send action, message

      expect(Audit.count).to be > 1
      audit = Audit.first
      expect(audit.action).to eq action
      expect(audit.auditable_type).to eq DockerRepo.name
      expect(audit.auditable_id).to eq repo_id
      expect(audit.auditable_descriptor).to eq repo_name
      expect(audit.data['message']).to eq message
    end

    context 'for a non-existing repo' do
      let(:repo_id) { 'non-existent' }
      let(:repo_name) { 'nope' }

      it 'should log an error' do
        expect(Rails.logger).to receive(:error)
          .with("[DockerRepoLifecycleService] #{action} - could not find a DockerRepo with ID: '#{repo_id}' (name: '#{repo_name}')")

        subject.send action, message
      end
    end

    context 'when the result is \'Failed\'' do
      let(:result_status) { 'Failed' }

      it 'should mark the repo as failed' do
        subject.send action, message

        expect(docker_repo.reload.failed?).to be true
      end
    end
  end

  describe '#handle_create_result' do
    it_behaves_like 'common message handling', 'handle_create_result' do
      it 'should update the status of the repo and any metadata' do
        subject.handle_create_result message

        updated = DockerRepo.find docker_repo.id
        expect(updated.url).to eq message['resource']['url']
        expect(updated).to be_active
      end
    end
  end

  describe '#handle_delete_result' do
    it_behaves_like 'common message handling', 'handle_delete_result' do
      it 'should destroy the record and log an audit' do
        expect(DockerRepo.exists?(docker_repo.id)).to be true

        subject.handle_delete_result message

        expect(DockerRepo.exists?(docker_repo.id)).to be false

        audit = Audit.last
        expect(audit.action).to eq 'destroy'
        expect(audit.auditable_type).to eq DockerRepo.name
        expect(audit.auditable_id).to eq docker_repo.id
      end
    end
  end

end
