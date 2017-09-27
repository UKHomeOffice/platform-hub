module Kubernetes
  module RobotTokenService
    extend self

    KIND = :robot

    def get_by_cluster cluster
      Kubernetes::StaticTokenService.get_static_tokens_hash_record(cluster, KIND).data.map do |t|
        KubernetesRobotToken.from_data cluster, t
      end.sort_by!(&:name)
    end

    def get_by_user_id user_id
      Kubernetes::StaticTokenService.get_by_user_id(user_id, KIND).map do |(cluster, tokens)|
        tokens.map do |t|
          KubernetesRobotToken.from_data cluster, t
        end
      end.flatten.sort_by!(&:name)
    end

    def create_or_update cluster, name, groups, description, user_id
      Kubernetes::StaticTokenService.create_or_update cluster, KIND, name, groups, description, user_id
    end

    def delete cluster, name
      Kubernetes::StaticTokenService.delete_by_name cluster, KIND, name
    end

  end
end
