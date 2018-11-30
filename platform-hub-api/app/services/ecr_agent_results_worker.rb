class EcrAgentResultsWorker
  include Shoryuken::Worker

  shoryuken_options(
    queue: Rails.application.secrets.sqs_ecr_agent_results_queue,
    body_parser: :json,
    auto_delete: true,
  )

  HANDLERS = {
    DockerRepoLifecycleService::RESOURCE_TYPE => {
      'create' => -> (message) {
        docker_repo_lifecycle_service.handle_create_result message
      },
      'delete' => -> (message) {
        docker_repo_lifecycle_service.handle_delete_result message
      }
    },
    DockerRepoAccessPolicyService::RESOURCE_TYPE => {
      'update' => -> (message) {
        resource = message.fetch 'resource'
        id = resource.fetch 'id'
        docker_repo = DockerRepo.find_by id: id
        if docker_repo
          DockerRepoAccessPolicyService.new(docker_repo).handle_update_result message
        else
          Shoryuken.logger.error "Could not find Docker repo with ID: '#{is}' - this queue message will now be discarded without being processed"
        end
      }
    }
  }

  private_class_method def self.docker_repo_lifecycle_service
    @docker_repo_lifecycle_service ||= DockerRepoLifecycleService.new
  end

  def perform(sqs_msg, message)
    message_id = sqs_msg.message_id

    resource_type = message.fetch 'resource_type'
    action = message.fetch 'action'

    Shoryuken.logger.info "Processing message (ID: #{message_id}) for resource type '#{resource_type}' and action '#{action}'"

    handler = HANDLERS.dig resource_type, action

    if handler
      handler.call message
    else
      Shoryuken.logger.error "Could not find handle for resource type '#{resource_type}', action '#{action}' - this queue message will now be discarded without being processed"
    end
  end

end
