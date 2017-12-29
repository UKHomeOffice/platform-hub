namespace :kubernetes do

  desc "Trigger the Kubernetes sync tokens job if it's not already in the queue"
  task trigger_tokens_sync: :environment do
    Kubernetes::TokensSyncJobTriggerService.trigger
  end

  desc "Trigger the Kubernetes privileged tokens expirer job if it's not already in the queue"
  task trigger_tokens_expirer: :environment do
    Kubernetes::TokensExpirerJobTriggerService.trigger
  end

end
