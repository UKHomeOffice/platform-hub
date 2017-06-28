namespace :kubernetes do

  namespace :cluster do

    desc "Add kubernetes cluster to list of managed clusters"
    task :create_or_update, [:id, :description, :s3_region, :s3_bucket_name, :s3_access_key_id, :s3_secret_access_key, :object_key] => [:environment] do |t, args|

      unless [args.id, args.description, args.s3_region, args.s3_bucket_name, args.s3_access_key_id, args.s3_secret_access_key, args.object_key].all?
        raise "ERROR: Missing arguments!"
      end

      puts Kubernetes::ClusterService.create_or_update(args)
    end

    desc "Delete kubernetes cluster from list of managed clusters"
    task :delete, [:id] => [:environment] do |t, args|

      raise "ERROR: Missing argument!" if args.id.blank?

      puts Kubernetes::ClusterService.delete(args.id)
    end

  end

  
  namespace :static_token do

    desc "Creates or updates static token - `groups` as semicolon separated string of group names: 'group1;group2'."
    task :create_or_update, [:cluster, :kind, :user_name, :groups] => [:environment] do |t, args|

      unless [args.cluster, args.kind, args.user_name, args.groups].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`,`user_name`,`groups`."
      end

      puts Kubernetes::StaticTokenService.create_or_update(args.cluster, args.kind, args.user_name, args.groups.split(';'))
    end

    desc "Deletes static token"
    task :delete, [:cluster, :kind, :user_name] => [:environment] do |t, args|

      unless [args.cluster, args.kind, args.user_name].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`,`user_name`."
      end

      puts Kubernetes::StaticTokenService.delete_by_name(args.cluster, args.kind, args.user_name)
    end

    desc "Describes static token"
    task :describe, [:cluster, :kind, :user_name] => [:environment] do |t, args|

      unless [args.cluster, args.kind, args.user_name].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`,`user_name`."
      end

      puts Kubernetes::StaticTokenService.describe(args.cluster, args.kind, args.user_name)
    end

    desc "Imports static kubernetes tokens for given cluster and kind from a file and stores them as HashRecord"
    task :import, [:cluster, :kind, :tokens_file_path] => [:environment] do |t, args|
      
      unless [args.cluster, args.kind].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`."
      end

      puts Kubernetes::StaticTokenService.import(args.cluster, args.kind, args.tokens_file_path)
    end

  end
end
