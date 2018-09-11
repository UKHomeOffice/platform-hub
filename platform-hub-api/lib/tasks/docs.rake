namespace :docs do

  desc "Trigger the docs sync job if it's not already in the queue"
  task trigger_docs_sync: :environment do
    Docs::DocsSyncJobTriggerService.trigger
  end

end
