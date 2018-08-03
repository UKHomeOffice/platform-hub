module HelpSearchIndexEnsurerJobTriggerService
  extend self

  def trigger
    if HelpSearchIndexEnsurerJob.is_already_queued?
      Rails.logger.info 'Help search index ensurer job already in queue... will not trigger another one'
    else
      Rails.logger.info 'Triggering the help search index ensurer job'
      HelpSearchIndexEnsurerJob.perform_later
    end
  end
end
