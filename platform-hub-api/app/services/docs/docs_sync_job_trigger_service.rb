module Docs
  module DocsSyncJobTriggerService
    extend self

    def trigger
      if !FeatureFlagService.is_enabled?(:docs_sync)
        Rails.logger.info 'Docs sync feature flag is turned off... will not trigger docs_sync sync job'
      elsif DocsSyncJob.is_already_queued?
        Rails.logger.info 'Docs sync job already in queue... will not trigger another one'
      else
        Rails.logger.info 'Triggering the docs sync job'
        DocsSyncJob.perform_later
      end
    end
  end
end
