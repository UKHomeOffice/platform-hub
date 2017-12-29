namespace :announcements do

  desc "Trigger the announcements processor job if it's not already in the queue"
  task trigger_processor_job: :environment do
    AnnouncementsProcessorJobTriggerService.trigger
  end

end
