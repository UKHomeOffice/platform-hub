class DockerRepoLifecycleService

  RESOURCE_TYPE = 'DockerRepository'.freeze

  def request_create service, params, audit_context
    docker_repo = service.docker_repos.new(params)
    docker_repo.provider = DockerRepo.providers[:ECR]

    if docker_repo.save

      message = {
        action: 'create',
        provider: docker_repo.provider,
        resource_type: RESOURCE_TYPE,
        resource: {
          id: docker_repo.id,
          project_id: docker_repo.service.project.friendly_id,
          name: docker_repo.name,
          base_uri: docker_repo.base_uri,
        }
      }

      DockerRepoQueueService.send_task message

      AuditService.log(
        context: audit_context,
        action: 'request_create',
        auditable: docker_repo
      )

    end

    docker_repo
  end

  def request_delete! docker_repo, audit_context
    id = docker_repo.id
    name = docker_repo.name
    service = docker_repo.service

    docker_repo.update! status: :deleting

    message = {
      action: 'delete',
      provider: docker_repo.provider,
      resource_type: RESOURCE_TYPE,
      resource: {
        id: docker_repo.id,
        project_id: docker_repo.service.project.friendly_id,
        name: docker_repo.name,
        base_uri: docker_repo.base_uri,
      }
    }

    DockerRepoQueueService.send_task message

    AuditService.log(
      context: audit_context,
      action: 'request_delete',
      auditable: docker_repo,
      associated: service,
      comment: "User '#{audit_context[:user].email}' has requested deletion of Docker repo: '#{name}' (ID: #{id}) in project '#{service.project.shortname}'"
    )
  end

  def handle_create_result message
    handle_result message, 'handle_create_result' do |docker_repo|
      docker_repo.update!(
        base_uri: message['resource']['base_uri'],
        status: DockerRepo.statuses[:active]
      )

      AuditService.log(
        action: 'create',
        auditable: docker_repo,
        comment: "Backend integration service successfully created Docker repo from provider: #{docker_repo.provider}"
      )
    end
  end

  def handle_delete_result message
    handle_result message, 'handle_delete_result' do |docker_repo|
      docker_repo.destroy!

      AuditService.log(
        action: 'destroy',
        auditable: docker_repo,
        comment: "Backend integration service successfully deleted Docker repo from provider: #{docker_repo.provider}"
      )
    end
  end

  private

  def handle_result message, action
    audit_message message, action

    docker_repo = load_docker_repo message['resource'], action

    return if docker_repo.nil?

    status = message['result']['status']
    case status
    when 'Complete'
      yield docker_repo
    when 'Failed'
      docker_repo.failed!
    else
      raise "Unknown status '#{status}' received from backend integration service"
    end
  end

  def audit_message message, action
    Audit.create!(
      action: action,
      auditable_type: DockerRepo.name,
      auditable_id: message['resource']['id'],
      auditable_descriptor: message['resource']['name'],
      data: { 'message' => message },
    )
  rescue => e
    Rails.logger.error "Failed to log audit - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join("--")}"
  end

  def load_docker_repo resource, action
    id = resource['id']
    name = resource['name']

    docker_repo = DockerRepo.find_by id: id

    if docker_repo.nil?
      Rails.logger.error "[DockerRepoLifecycleService] #{action} - could not find a DockerRepo with ID: '#{id}' (name: '#{name}')"
    end

    docker_repo
  end

end
