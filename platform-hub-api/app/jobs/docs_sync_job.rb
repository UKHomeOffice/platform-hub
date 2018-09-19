class DocsSyncJob < ApplicationJob
  queue_as :docs_sync

  def self.is_already_queued?
    Delayed::Job.where(queue: :docs_sync).count > 0
  end

  def perform docs_source = nil
    return unless FeatureFlagService.is_enabled?(:docs_sync)

    service = Docs::DocsSyncService.new(help_search_service: HelpSearchService.instance)

    if docs_source
      service.sync docs_source
    else
      service.sync_all
    end
  end
end
