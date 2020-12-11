module Kubernetes
  module KubernetesTokensService
    extend self

    def is_user_a_member_of_project? project_id, user_id
      project_scope.exists? project_id: project_id, user_id: user_id
    end
    def is_user_a_holder_of_token? tokenable, cluster_id, project_id
      scope.user.by_tokenable(tokenable).by_cluster(cluster_id).by_project(project_id).exists? tokenable: tokenable, cluster_id: cluster_id, project_id: project_id
    end

    private

    def scope
      KubernetesToken
    end

    def project_scope
      ProjectMembership
    end

  end
end
