module Kubernetes
  module TokensExpirerJobTriggerService
    extend self

    def trigger
      if !FeatureFlagService.is_enabled?(:kubernetes_tokens)
        Rails.logger.info 'Kubernetes tokens feature flag is turned off... will not trigger token expirer job'
      elsif TokenExpirerJob.is_already_queued?
        Rails.logger.info 'tokens expirer job already in queue... will not trigger another one'
      else
        Rails.logger.info 'Triggering the tokens expirer job'
        TokenExpirerJob.perform_now
      end
    end
  end
end
