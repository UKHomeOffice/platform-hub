module DockerRepoQueueService

  TASK_QUEUE_URLS = {
    DockerRepo.providers[:ECR] => Rails.application.secrets.sqs_ecr_agent_tasks_queue
  }.freeze

  extend self

  def send_task message
    queue_url = TASK_QUEUE_URLS[message.fetch(:provider)]
    Shoryuken::Client.queues(queue_url).send_message(message_body: message)
  end

end
