namespace :kubernetes do

  desc "Trigger the Kubernetes sync tokens job if it's not already in the queue"
  task trigger_tokens_sync: :environment do
    if !FeatureFlagService.is_enabled?(:kubernetes_tokens)
      puts 'Kubernetes tokens feature flag is turned off... will not trigger tokens sync job'
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

  namespace :cluster do

    desc "Add kubernetes cluster to list of managed clusters"
    task :create, [:name, :description, :s3_region, :s3_bucket_name, :s3_access_key_id, :s3_secret_access_key, :s3_object_key] => [:environment] do |t, args|

      unless [args.name, args.description, args.s3_region, args.s3_bucket_name, args.s3_access_key_id, args.s3_secret_access_key, args.s3_object_key].all?
        raise "ERROR: Missing arguments!"
      end

      puts KubernetesCluster.create(args)
    end

    desc "Delete kubernetes cluster from list of managed clusters"
    task :delete, [:name] => [:environment] do |t, args|

      raise "ERROR: Missing argument!" if args.name.blank?

      puts KubernetesCluster.friendly.destroy(args.name)
    end

  end

end
