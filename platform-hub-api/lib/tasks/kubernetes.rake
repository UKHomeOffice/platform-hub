namespace :kubernetes do
  
  namespace :robots do

    desc "Creates or updates robot token - `groups` as space separated string of group names: 'group1 group2'."
    task :create_or_update, [:cluster, :robot_name, :groups] => [:environment] do |t, args|

      unless [args.cluster, args.robot_name, args.groups].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`, `groups`."
      end

      puts Kubernetes::RobotTokenService.create_or_update(args.cluster, args.robot_name, args.groups.split(' '))
    end

    desc "Deletes robot token"
    task :delete, [:cluster, :robot_name] => [:environment] do |t, args|

      unless [args.cluster, args.robot_name].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`."
      end

      puts Kubernetes::RobotTokenService.delete(args.cluster, args.robot_name)
    end

    desc "Describes robot token"
    task :describe, [:cluster, :robot_name] => [:environment] do |t, args|

      unless [args.cluster, args.robot_name].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`."
      end

      puts Kubernetes::RobotTokenService.describe(args.cluster, args.robot_name)
    end

  end

  namespace :static do

    desc "Creates static kubernetes tokens for given cluster and kind from a file and stores them as HashRecord"
    task :tokens, [:cluster, :kind, :tokens_file_path] => [:environment] do |t, args|
      
      unless [args.cluster, args.kind].all?
        raise "ERROR: Missing arguments! Required args: `cluster`,`kind`."
      end

      # Static tokens can be imported from a file or standard input.
      # If file path hasn't been provided in args user will be prompt to input data manually.

      if args.tokens_file_path.present? # Load from file
        if File.exists? args.tokens_file_path
          data = File.read(args.tokens_file_path).split("\n").map do |l|
            parse_record(l)
          end
        else
          raise "ERROR: File doesn't exist!"
        end
      else # Prompt user for manual input        
        begin
          STDOUT.puts "Input tokens (in source format) and hit ENTER):"
          input = multi_gets
        end until input.present?

        data = input.split("\n").map do |l|
          parse_record(l)
        end
      end

      key = "#{args.cluster}-static-#{args.kind}-tokens"

      if data.present?
        if HashRecord.kubernetes.exists?(id: key)
          HashRecord.kubernetes.find_by!(id: key).destroy
        end

        HashRecord.kubernetes.create!(id: key, data: data)

        puts "INFO: Created kubernetes HashRecord for #{key}!"
      else
        puts "INFO: Doing nothing. Empty static tokens data!"
      end
    end

    def multi_gets all_text=""
      while all_text << STDIN.gets
        return all_text if all_text["\n\n"]
      end
    end

    def parse_record(record)
      parts = record.gsub('"','').split(',')
      Hashie::Mash.new(
        token: ENCRYPTOR.encrypt(parts[0]),
        user: parts[1],
        uid: parts[2],
        groups: parts.size > 3 ? parts[3..-1] : [],
      )
    end

  end
end
