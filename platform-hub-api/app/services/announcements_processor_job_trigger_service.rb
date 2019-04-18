module AnnouncementsProcessorJobTriggerService
  extend self

  def trigger
    if !FeatureFlagService.is_enabled?(:announcements)
      Rails.logger.info 'Announcements feature flag is turned off... will not trigger announcements processor job'
    elsif AnnouncementsProcessorJob.is_already_queued?
      Rails.logger.info 'Announcements processor job already in queue... will not trigger another one'
    else
      Rails.logger.info 'Triggering the announcements processor job'
      AnnouncementsProcessorJob.perform_later
    end
  end
end
