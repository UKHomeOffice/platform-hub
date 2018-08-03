namespace :help_search do

  desc "Trigger the help search index ensurer job if it's not already in the queue"
  task trigger_index_ensurer_job: :environment do
    HelpSearchIndexEnsurerJobTriggerService.trigger
  end

end
