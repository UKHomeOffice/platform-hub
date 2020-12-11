module Kubernetes
  module PrivilegedTokensExpirerJobTriggerService
    extend self

    def trigger
      if !FeatureFlagService.is_enabled?(:kubernetes_tokens)
        Rails.logger.info 'Kubernetes tokens feature flag is turned off... will not trigger token expirer job'
      elsif PrivilegedTokenExpirerJob.is_already_queued?
        Rails.logger.info 'Privileged tokens expirer job already in queue... will not trigger another one'
      else
        Rails.logger.info 'Triggering the privileged tokens expirer job'
        PrivilegedTokenExpirerJob.perform_later
      end
    end
  end
end
