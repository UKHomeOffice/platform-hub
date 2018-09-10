class DocsSyncJob < ApplicationJob
  queue_as :docs_sync

  def self.is_already_queued?
    Delayed::Job.where(queue: :docs_sync).count > 0
  end

  def perform
    return unless FeatureFlagService.is_enabled?(:docs_sync)

    Docs::DocsSyncService.new(help_search_service: HelpSearchService.instance).sync_all
  end
end
