module AnnouncementsProcessorJobTriggerService
  extend self

  def trigger
    if AnnouncementsProcessorJob.is_already_queued?
      Rails.logger.info 'Announcements processor job already in queue... will not trigger another one'
    else
      Rails.logger.info 'Triggering the announcements processor job'
      AnnouncementsProcessorJob.perform_later
    end
  end
end
