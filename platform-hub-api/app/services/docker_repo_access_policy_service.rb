class DockerRepoAccessPolicyService

  RESOURCE_TYPE = 'DockerRepositoryAccessPolicy'.freeze

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

    send_update_message

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

  def request_remove_user! user
    @docker_repo.with_lock do
      access = @docker_repo.access

      user_entry = access['users'].find { |u| u['username'] == user.email }

      if user_entry
        user_entry['status'] = DockerRepo::ACCESS_STATUS[:removing]

        @docker_repo.save!

        send_update_message

        AuditService.log(
          action: 'request_access_remove_user',
          auditable: @docker_repo,
          comment: "User '#{user.email}' has been requested to be removed access to this Docker repo"
        )
      end
    end
  end

  def handle_update_result message
    id = message['resource']['id']
    name = message['resource']['name']

    begin
      Audit.create!(
        action: 'handle_access_update_result',
        auditable_type: DockerRepo.name,
        auditable_id: message['resource']['id'],
        auditable_descriptor: message['resource']['name'],
        data: { 'message' => message },
      )
    rescue => e
      Rails.logger.error "Failed to log audit - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("--")}"
    end

    docker_repo = DockerRepo.find_by id: id

    if docker_repo.nil?
      Rails.logger.error "[DockerRepoAccessPolicyService] handle_update_result - could not find a DockerRepo with ID: '#{id}' (name: '#{name}')"
      return
    end

    # Even if the message has a `Failed` status, it's possible that individual
    # access items have succeeded. So we need to go through each one and figure
    # out if our internal state needs updating.

    ActiveRecord::Base.transaction do

      docker_repo.access['robots'] = process_items_from_result(
        item_type: 'robot',
        items: message['resource']['robots'],
        current: docker_repo.access['robots'],
        check_username: -> (_) { true },
        get_credentials: -> (item) { item['credentials'] },
        set_credentials: -> (item, credentials) { item['credentials'] = credentials }
      )

      docker_repo.access['users'] = process_items_from_result(
        item_type: 'user',
        items: message['resource']['users'],
        current: docker_repo.access['users'],
        check_username: -> (email) {
          user = User.find_by email: email
          user.present? && ProjectMembershipsService.is_user_a_member_of_project?(
              docker_repo.service.project_id,
              user.id
            )
        },
        get_credentials: -> (item) {
          username = item['username']
          user = User.find_by email: username
          if user
            (user.ecr_identity.try(:data) || {})['credentials'].presence
          end
        },
        set_credentials: -> (item, credentials) {
          username = item['username']
          user = User.find_by email: username
          if user
            identity = user.ecr_identity || user.identities.build(
              provider: Identity.providers[:ecr],
              external_id: username,
              external_username: username,
            )
            identity.data = { 'credentials' => credentials }
            identity.save!
          end
        },
        fields_to_update: [ 'writable' ]
      )

      docker_repo.save!

    end

    AuditService.log(
      action: 'access_update',
      auditable: docker_repo,
      comment: "Backend status was: #{message['result']['status']}"
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
        # OR 'failed', but now has been requested to be added back in again.
        if i['status'] == DockerRepo::ACCESS_STATUS[:removing] ||
          i['status'] == DockerRepo::ACCESS_STATUS[:failed]
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

  def send_update_message
    message = {
      action: 'update',
      provider: @docker_repo.provider,
      resource_type: RESOURCE_TYPE,
      resource: {
        id: @docker_repo.id,
        repository: @docker_repo.name,
        robots: wanted_items(@docker_repo.access['robots'], ['username']),
        users: wanted_items(@docker_repo.access['users'], ['username', 'writable'])
      }
    }

    DockerRepoQueueService.send_task message
  end

  def process_items_from_result item_type:, items:, current:, check_username:, get_credentials:, set_credentials:, fields_to_update: []
    processed = Set.new

    items.each do |r|
      username = r['username']

      if check_username.call username
        processed.add username

        existing = current.find { |i| i['username'] == username }

        if existing
          if existing['status'] == DockerRepo::ACCESS_STATUS[:removing]
            existing['status'] = DockerRepo::ACCESS_STATUS[:failed]
          else
            credentials = r['credentials']
            if credentials
              set_credentials.call existing, credentials

              fields_to_update.each do |f|
                existing[f] = r[f]
              end

              existing['status'] = DockerRepo::ACCESS_STATUS[:active]
            elsif existing['status'] == DockerRepo::ACCESS_STATUS[:pending]
              # If we already have credentials then we assume those are still valid
              if get_credentials.call existing
                existing['status'] = DockerRepo::ACCESS_STATUS[:active]
              else
                existing['status'] = DockerRepo::ACCESS_STATUS[:failed]
              end
            end
          end
        else
          # Unknown item but let's add it anyway

          Rails.logger.warn "[DockerRepoAccessPolicyService] process_items_from_result - unknown #{item_type} was detected - username: '#{username}' - adding anyway"

          new_item = r.merge 'status' => DockerRepo::ACCESS_STATUS[:active]
          credentials = r['credentials']
          set_credentials.call new_item, credentials if credentials
          current << new_item
        end

      else
        Rails.logger.error "[DockerRepoAccessPolicyService] process_items_from_result - username for #{item_type} did not pass the check - username: '#{username}' - ignoring this item and removing from access"
      end
    end

    # Remove items not processed/seen in the backend response
    current.select do |r|
      processed.include? r['username']
    end
  end

  def wanted_items items, fields_to_output
    items.select do |i|
      i['status'] != DockerRepo::ACCESS_STATUS[:removing] &&
        i['status'] != DockerRepo::ACCESS_STATUS[:failed]
    end.map do |i|
      i.slice(*fields_to_output)
    end
  end

end
