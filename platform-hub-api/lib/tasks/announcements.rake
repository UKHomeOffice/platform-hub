namespace :announcements do

  desc "Trigger the announcements processor job if it's not already in the queue"
  task trigger_processor_job: :environment do
    if AnnouncementsProcessorJob.is_already_queued
      puts 'Announcements processor job already in queue... will not trigger another one'
    else
      puts 'Triggering the announcements processor job'
      AnnouncementsProcessorJob.perform_later
    end
  end

end
