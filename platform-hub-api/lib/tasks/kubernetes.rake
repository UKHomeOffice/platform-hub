namespace :kubernetes do

  desc "Trigger the Kubernetes sync tokens job if it's not already in the queue"
  task trigger_tokens_sync: :environment do
    if !FeatureFlagService.all_enabled?([
      :kubernetes_tokens_sync,
      :kubernetes_tokens
    ])
      puts 'Kubernetes tokens and/or tokens sync feature flags are turned off... will not trigger tokens sync job'
    elsif TokensSyncJob.is_already_queued
      puts 'Tokens sync job already in queue... will not trigger another one'
    else
      puts 'Triggering the tokens sync job'
      TokensSyncJob.perform_later
    end
  end

  desc "Trigger the Kubernetes privileged tokens expirer job if it's not already in the queue"
  task trigger_tokens_expirer: :environment do
    if !FeatureFlagService.is_enabled?(:kubernetes_tokens)
      puts 'Kubernetes tokens feature flag is turned off... will not trigger token expirer job'
    elsif PrivilegedTokenExpirerJob.is_already_queued
      puts 'Privileged tokens expirer job already in queue... will not trigger another one'
    else
      puts 'Triggering the privileged tokens expirer job'
      PrivilegedTokenExpirerJob.perform_later
    end
  end

end
