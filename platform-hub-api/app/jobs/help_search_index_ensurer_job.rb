class HelpSearchIndexEnsurerJob < ApplicationJob
  queue_as :help_search_index_ensurer

  def self.is_already_queued?
    Delayed::Job.where(queue: :help_search_index_ensurer).count > 0
  end

  def perform
    if !index_exists || index_is_empty
      HelpSearchService.instance.reindex_all force: true
    end
  end

  private

  def index_exists
    HelpSearchService.instance.repository.index_exists?
  end

  def index_is_empty
    HelpSearchService.instance.repository.count == 0
  end
end
