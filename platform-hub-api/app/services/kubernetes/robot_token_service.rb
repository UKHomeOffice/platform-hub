module Kubernetes
  module RobotTokenService
    extend self

    # Static robot tokens are stored in HashRecord as:
    # data: [
    #   {"token" => "token1", user" => "user1", "uid" => "uid1", "groups" => ["group1","group2"]}
    #   {"token" => "token2", user" => "user2", "uid" => "uid2", "groups" => []}
    #   ...
    # ]
    def create_or_update(cluster, robot_name, groups = [])
      robot_tokens = get_robot_tokens(cluster)

      record = robot_tokens.data.find do |t|
        t['user'] == robot_name.to_s
      end

      if record.nil?
        token = Kubernetes::TokenService.send(:generate_secure_random)
        record = Hashie::Mash.new(
          token: token,
          user: robot_name,
          uid: Kubernetes::TokenService.send(:generate_secure_random),
          groups: Kubernetes::TokenService.send(:cleanup, groups)
        )

        robot_tokens.data << record
      else
        record['groups'] = groups.present? ? 
          Kubernetes::TokenService.send(:cleanup, groups) : []
      end

      robot_tokens.save!
      puts "Created/updated robot account for `#{robot_name}` (token: #{record['token']})"
    end

    def delete(cluster, robot_name)
      robot_tokens = get_robot_tokens(cluster)

      robot_tokens.data.reject! do |t|
        t['user'] == robot_name.to_s
      end

      robot_tokens.save!
      puts "Deleted robot account for `#{robot_name.to_s}`"
    end

    def describe(cluster, robot_name)
      robot_tokens = get_robot_tokens(cluster)

      record = robot_tokens.data.find do |t|
        t['user'] == robot_name.to_s
      end

      if record.present?
        record
      else
        "Account not found!"
      end
    end

    private

    def get_robot_tokens(cluster)
      HashRecord.kubernetes.find_by!(id: "#{cluster.to_s}-static-robot-tokens")
    end

  end
end
