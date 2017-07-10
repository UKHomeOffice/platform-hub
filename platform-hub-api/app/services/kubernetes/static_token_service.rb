module Kubernetes
  module StaticTokenService
    extend self

    # Static tokens are stored in HashRecord as:
    # data: [
    #   {"token" => "token1", user" => "user1", "uid" => "uid1", "groups" => ["group1","group2"]}
    #   {"token" => "token2", user" => "user2", "uid" => "uid2", "groups" => []}
    #   ...
    # ]
    # Note: All tokens are encrypted!

    def create_or_update(cluster, kind, user_name, groups = [])
      static_tokens = get_static_tokens(cluster, kind)

      static_tokens.with_lock do
        record = static_tokens.data.find do |t|
          t['user'] == user_name.to_s
        end

        if record.nil?
          token = Kubernetes::TokenService.generate_secure_random
          record = {
            token: ENCRYPTOR.encrypt(token),
            user: user_name,
            uid: Kubernetes::TokenService.generate_secure_random,
            groups: Kubernetes::TokenService.cleanup_groups(groups)
          }

          static_tokens.data << record
        else
          record['groups'] = groups.present? ? 
            Kubernetes::TokenService.cleanup_groups(groups) : []
        end

        static_tokens.save!

        "Created/updated #{kind} account for `#{user_name}` (token: #{ENCRYPTOR.decrypt(record.with_indifferent_access['token'])})"
      end      
    end

    def delete_by_user_name(cluster, kind, user_name)
      static_tokens = get_static_tokens(cluster, kind)

      static_tokens.with_lock do
        static_tokens.data.reject! do |t|
          t['user'] == user_name.to_s
        end

        static_tokens.save!

        "Deleted #{kind} account for `#{user_name.to_s}`"
      end
    end

    def delete_by_token(cluster, kind, token)
      static_tokens = get_static_tokens(cluster, kind)

      static_tokens.with_lock do
        static_tokens.data.reject! do |t|
          ENCRYPTOR.decrypt(t['token']) == token
        end

        static_tokens.save!

        "Deleted #{kind} account with token `#{token.to_s}`"
      end
    end

    def describe(cluster, kind, user_name)
      static_tokens = get_static_tokens(cluster, kind)

      record = static_tokens.data.find do |t|
        t['user'] == user_name.to_s
      end

      if record.present?
        record
      else
        "Account not found!"
      end
    end

    def import(cluster, kind, tokens_file_path = nil)
      # Static tokens can be imported from a file or standard input.
      # If file path hasn't been provided in args user will be prompt to input data manually.

      if tokens_file_path.present? # Load from file
        if File.exists? tokens_file_path
          data = File.read(tokens_file_path).split("\n").map do |l|
            parse_record(l)
          end
        else
          raise "File doesn't exist!"
        end
      else # Prompt user for manual input
        begin
          puts "Input tokens (in source format) and hit ENTER twice to confirm):"
          input = multi_gets
        end until input.present?

        data = input.split("\n").map do |l|
          parse_record(l)
        end
      end

      key = "#{cluster.to_s}-static-#{kind.to_s}-tokens"

      if data.present?
        if HashRecord.kubernetes.exists?(id: key)
          HashRecord.kubernetes.find_by!(id: key).destroy
        end

        HashRecord.kubernetes.create!(id: key, data: data)

        "Created kubernetes HashRecord for #{key}!"
      else
        "Doing nothing. Empty static tokens data!"
      end
    end

    private

    def get_static_tokens(cluster, kind)
      HashRecord.kubernetes.find_by!(id: "#{cluster.to_s}-static-#{kind.to_s}-tokens")
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
