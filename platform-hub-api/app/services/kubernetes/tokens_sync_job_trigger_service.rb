module Kubernetes
  module TokensSyncJobTriggerService
    extend self

    def trigger
      if !FeatureFlagService.all_enabled?([
        :kubernetes_tokens_sync,
        :kubernetes_tokens
      ])
        Rails.logger.info 'Kubernetes tokens and/or tokens sync feature flags are turned off... will not trigger tokens sync job'
      elsif TokensSyncJob.is_already_queued?
        Rails.logger.info 'Tokens sync job already in queue... will not trigger another one'
      else
        Rails.logger.info 'Triggering the tokens sync job'
        TokensSyncJob.perform_later
      end
    end
  end
end
