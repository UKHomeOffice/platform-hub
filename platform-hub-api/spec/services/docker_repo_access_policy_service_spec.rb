require 'rails_helper'

describe DockerRepoAccessPolicyService, type: :service do

  subject do
    DockerRepoAccessPolicyService.new docker_repo
  end

  let!(:project) { create :project }
  let!(:service) { create :service, project: project }

  let! :project_member_1 do
    create(:project_membership, project: project).user
  end
  let! :project_member_2 do
    create(:project_membership, project: project).user
  end

  let!(:docker_repo) { create :docker_repo, service: service }

  let(:user) { create :user }
  let(:audit_context) { { user: user } }

  context '#request_update!' do

    context 'with invalid inputs' do

      let!(:not_a_project_member) { create :user }

      it 'should throw an error if a robot name doesn\'t start with the project slug' do
        robots = [ { 'username' => 'doesnotstart_with_project_slug' } ]
        expect {
          subject.request_update! robots, [], audit_context
        }.to raise_error(DockerRepoAccessPolicyService::Errors::InvalidRobotName)
      end

      it 'should throw an error if a user is not a project team member' do
        users = [ { 'username' => not_a_project_member.email } ]
        expect {
          subject.request_update! [], users, audit_context
        }.to raise_error(DockerRepoAccessPolicyService::Errors::UserIsNotAMemberOfProject)
      end

    end

    context 'with valid inputs' do

      let :robots do
        [
          { 'username' => "#{project.slug}_deploy" },
          { 'username' => "#{project.slug}_ci" },
        ]
      end

      let :users do
        [
          { 'username' => project_member_1.email, 'writable' => false },
          { 'username' => project_member_2.email, 'writable' => true },
        ]
      end

      let :expected_access do
        {
          'robots' => robots.map { |r| r.merge 'status' => 'pending' }.sort_by { |r| r['username'] },
          'users' => users.map { |u| u.merge 'status' => 'pending' }.sort_by { |r| r['username'] },
        }
      end

      it 'should update the access for the Docker repo as expected' do
        subject.request_update! robots, users, audit_context

        docker_repo.reload
        expect(docker_repo.access).to eq expected_access
      end

      it 'logs an audit' do
        expect(Audit.count).to eq 0

        subject.request_update! robots, users, audit_context

        expect(Audit.count).to eq 1
        audit = Audit.first
        expect(audit.action).to eq 'request_access_update'
        expect(audit.auditable).to eq docker_repo
        expect(audit.user).to eq user
      end

      context 'with existing access already set' do
        before do
          docker_repo.update! access: expected_access
        end

        it 'marks everything as removing when inputs are empty lists' do
          subject.request_update! [], [], audit_context

          expected_robots = expected_access['robots'].map { |r| r.merge 'status' => 'removing' }
          expected_users = expected_access['users'].map { |u| u.merge 'status' => 'removing' }

          docker_repo.reload
          expect(docker_repo.access['robots']).to eq expected_robots
          expect(docker_repo.access['users']).to eq expected_users
        end

        it 'marks specific items as removing when they are not present in the inputs' do
          robot_to_remove = robots.first
          user_to_remove = users.second

          subject.request_update! robots - [robot_to_remove], users - [user_to_remove], audit_context

          expected_robots = expected_access['robots'].map do |r|
            if r['username'] == robot_to_remove['username']
              r.merge 'status' => 'removing'
            else
              r
            end
          end
          expected_users = expected_access['users'].map do |u|
            if u['username'] == user_to_remove['username']
              u.merge 'status' => 'removing'
            else
              u
            end
          end

          docker_repo.reload
          expect(docker_repo.access['robots']).to eq expected_robots
          expect(docker_repo.access['users']).to eq expected_users
        end

        it 'adds new items as expected' do
          new_robot = { 'username' => "#{project.slug}_ci2" }

          subject.request_update! robots + [new_robot], users, audit_context

          expected_robots = (
            expected_access['robots'] +
            [new_robot.merge('status' => 'pending')]
          ).sort_by { |i| i['username'] }
          expected_users = expected_access['users']

          docker_repo.reload
          expect(docker_repo.access['robots']).to eq expected_robots
          expect(docker_repo.access['users']).to eq expected_users
        end

        it 'updates fields as expected' do
          user_to_update = users.first
          user_to_update = user_to_update.merge 'writable' => !user_to_update['writable']

          users_to_not_update = users[1..-1]

          subject.request_update! robots, users_to_not_update + [user_to_update], audit_context

          expected_robots = expected_access['robots']
          expected_users = expected_access['users'].map do |u|
            if u['username'] == user_to_update['username']
              u.merge 'writable' => user_to_update['writable']
            else
              u
            end
          end

          docker_repo.reload
          expect(docker_repo.access['robots']).to eq expected_robots
          expect(docker_repo.access['users']).to eq expected_users
        end

        it 'handles the special case of a marked removal now being added back in' do
          robot_to_remove = robots.first

          subject.request_update! robots - [robot_to_remove], users, audit_context

          subject.request_update! robots, users, audit_context

          docker_repo.reload
          expect(docker_repo.access).to eq expected_access
        end
      end

    end

  end

  context '#handle_update_result' do
    let :message do
      {
        'resource' => {
          'id' => repo_id,
          'name' => repo_name,
          'url' => 'a_url',
          'robots' => robots,
          'users' => users,
        },
        'result' => {
          'status' => result_status
        }
      }
    end

    let(:repo_id) { docker_repo.id }
    let(:repo_name) { docker_repo.name }

    let(:robots) { [] }
    let(:users) { [] }

    let(:result_status) { 'Complete' }

    it 'should log an audit for the message' do
      expect(Audit.count).to eq 0

      subject.handle_update_result message

      expect(Audit.count).to be > 1
      audit = Audit.first
      expect(audit.action).to eq 'handle_access_update_result'
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
          .with("[DockerRepoAccessPolicyService] handle_update_result - could not find a DockerRepo with ID: '#{repo_id}' (name: '#{repo_name}')")

        subject.handle_update_result message
      end
    end

    context 'for an existing repo' do

      let! :project_member_2_ecr_identity do
        create :ecr_identity, user: project_member_2
      end

      let! :project_member_3 do
        create(:project_membership, project: project).user
      end

      let! :project_member_4 do
        create(:project_membership, project: project).user
      end
      let! :project_member_4_ecr_identity do
        create :ecr_identity, user: project_member_4
      end

      let(:unknown_user_email) { 'whodis?@example.org' }
      let!(:no_longer_a_project_member) { create :user }

      let :existing_access do
        {
          'robots' => [
            { 'username' => "#{project.slug}_robot_1", 'status' => 'pending' },
            { 'username' => "#{project.slug}_robot_2", 'status' => 'pending' },
            { 'username' => "#{project.slug}_robot_3", 'status' => 'active' },
            { 'username' => "#{project.slug}_robot_4", 'status' => 'removing' },
            { 'username' => "#{project.slug}_robot_5", 'status' => 'removing' },
          ],
          'users' => [
            { 'username' => project_member_1.email, 'writable' => false, 'status' => 'pending' },
            { 'username' => project_member_2.email, 'writable' => true, 'status' => 'removing' },
            { 'username' => project_member_3.email, 'writable' => true, 'status' => 'removing' },
            { 'username' => project_member_4.email, 'writable' => true, 'status' => 'active' },
            { 'username' => unknown_user_email, 'writable' => false, 'status' => 'pending' },
            { 'username' => no_longer_a_project_member.email, 'writable' => false, 'status' => 'active' },
          ]
        }
      end

      let :robots do
        [
          { 'username' => "#{project.slug}_robot_1", 'credentials' => { 'robot_1' => 'robot_1' } },
          { 'username' => "#{project.slug}_robot_2" },
          { 'username' => "#{project.slug}_robot_3" },
          { 'username' => "#{project.slug}_robot_5" },
        ]
      end

      let :users do
        [
          { 'username' => project_member_1.email, 'writable' => true, 'credentials' => { 'project_member_1' => 'project_member_1' } },
          { 'username' => project_member_3.email, 'writable' => true },
          { 'username' => unknown_user_email, 'writable' => false },
          { 'username' => no_longer_a_project_member.email, 'writable' => false },
        ]
      end

      before do
        docker_repo.update! access: existing_access
      end

      let :expected_access do
        {
          'robots' => [
            { 'username' => "#{project.slug}_robot_1", 'status' => 'active', 'credentials' => { 'robot_1' => 'robot_1' } },
            { 'username' => "#{project.slug}_robot_2", 'status' => 'failed' },
            { 'username' => "#{project.slug}_robot_3", 'status' => 'active' },
            { 'username' => "#{project.slug}_robot_5", 'status' => 'failed' },
          ],
          'users' => [
            { 'username' => project_member_1.email, 'writable' => true, 'status' => 'active' },
            { 'username' => project_member_3.email, 'writable' => true, 'status' => 'failed' },
          ]
        }
      end

      it 'should update the repo\'s access as expected, create any required ecr identities and log an audit' do
        expect(project_member_1.reload.ecr_identity).to be nil
        expect(project_member_2.reload.ecr_identity).to eq project_member_2_ecr_identity
        expect(project_member_3.reload.ecr_identity).to be nil
        expect(project_member_4.reload.ecr_identity).to eq project_member_4_ecr_identity

        subject.handle_update_result message

        updated = DockerRepo.find docker_repo.id
        expect(updated.access).to eq expected_access

        expect(project_member_1.reload.ecr_identity.attributes).to include(
          'provider' => 'ecr',
          'external_id' => project_member_1.email,
          'external_username' => project_member_1.email,
          'data' => { 'credentials' => { 'project_member_1' => 'project_member_1' } }
        )
        expect(project_member_2.reload.ecr_identity).to eq project_member_2_ecr_identity
        expect(project_member_3.reload.ecr_identity).to be nil
        expect(project_member_4.reload.ecr_identity).to eq project_member_4_ecr_identity

        audit = Audit.last
        expect(audit.action).to eq 'access_update'
        expect(audit.auditable).to eq docker_repo
      end

    end

  end

end
