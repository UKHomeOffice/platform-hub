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
        expect(audit.auditable_type).to eq DockerRepo.name
        expect(audit.auditable_id).to eq docker_repo.id
        expect(audit.user.id).to eq user.id
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

end
