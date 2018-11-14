class DockerRepoAccessPolicyService

  module Errors
    class InvalidRobotName < StandardError
    end

    class UserIsNotAMemberOfProject < StandardError
    end
  end

  def initialize docker_repo
    @docker_repo = docker_repo
  end

  # Expected input structures:
  # - `robots`: an Array of Hashes where each Hash follows:
  #   { 'username' => '<valid string for robot username>' }
  # - `users`: an Array of Hashes where each Hash follows:
  #   { 'username' => '<a valid project team member's email>', 'writable' => <Boolean> }
  def request_update! robots, users, audit_context
    @docker_repo.with_lock do
      validate_robots robots
      validate_users users

      access = @docker_repo.access

      access['robots'] = build_updated_list access['robots'], robots
      access['users'] = build_updated_list access['users'], users, fields_to_update: ['writable']

      @docker_repo.save!
    end

    id = @docker_repo.id
    name = @docker_repo.name
    service = @docker_repo.service

    AuditService.log(
      context: audit_context,
      action: 'request_access_update',
      auditable: @docker_repo,
      comment: "User '#{audit_context[:user].email}' has requested access updates to Docker repo: '#{name}' (ID: #{id}) in project '#{service.project.shortname}' - robots: #{robots.map{|r| r[:username]}.join(', ')}, users: #{users.map{|u| u[:username]}.join(', ')}"
    )
  end

  private

  def validate_robots robots
    project_slug = @docker_repo.service.project.slug

    raise Errors::InvalidRobotName if robots.any? do |r|
      !r['username'].start_with?("#{project_slug}_")
    end
  end

  def validate_users users
    project_id = @docker_repo.service.project.id

    raise Errors::UserIsNotAMemberOfProject if users.any? do |u|
      !ProjectMembershipsService.is_user_a_member_of_project?(
        project_id,
        User.find_by!(email: u['username']).id
      )
    end
  end

  def build_updated_list current, wanted, fields_to_update: []
    updated = []

    wanted_map = wanted.each_with_object({}) do |i, acc|
      acc[i['username']] = i
    end
    wanted_usernames = wanted_map.keys

    processed_usernames = []

    current.each do |i|
      username = i['username']

      if wanted_usernames.include?(username)
        fields_to_update.each do |f|
          i[f] = wanted_map[username][f]
        end

        # Special case: when an entry has previously been marked as 'removing'
        # but now has been requested to be added back in again.
        if i['status'] == DockerRepo::ACCESS_STATUS[:removing]
          i['status'] = DockerRepo::ACCESS_STATUS[:pending]
        end
      else
        # Mark for removal
        i['status'] = DockerRepo::ACCESS_STATUS[:removing]
      end

      updated << i

      processed_usernames << username
    end

    # Add new ones
    new_usernames = wanted_usernames - processed_usernames
    wanted.each do |i|
      username = i['username']
      if new_usernames.include? username
        updated << i.merge('status' => DockerRepo::ACCESS_STATUS[:pending])
      end
    end

    updated.sort_by { |i| i['username'] }
  end

end
