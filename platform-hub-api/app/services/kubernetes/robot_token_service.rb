module Kubernetes
  module RobotTokenService
    extend self

    KIND = :robot

    def get cluster
      Kubernetes::StaticTokenService.get_static_tokens_hash_record(cluster, KIND).data.map do |t|
        KubernetesRobotToken.from_data cluster, t
      end.sort_by!(&:name)
    end

    def create_or_update cluster, name, groups
      Kubernetes::StaticTokenService.create_or_update cluster, KIND, name, groups
    end

    def delete cluster, name
      Kubernetes::StaticTokenService.delete_by_user_name cluster, KIND, name
    end

  end
end
