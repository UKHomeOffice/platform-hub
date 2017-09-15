class Kubernetes::GroupsController < ApiJsonController

  # GET /kubernetes/groups/privileged
  def privileged
    authorize! :read, :groups
    kubernetes_groups = Kubernetes::TokenGroupService.privileged_groups
    render json: kubernetes_groups
  end

end
