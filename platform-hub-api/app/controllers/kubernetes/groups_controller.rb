class Kubernetes::GroupsController < ApiJsonController

  # GET /kubernetes/groups/privileged
  def privileged
    authorize! :read, :groups
    kubernetes_groups = HashRecord.kubernetes.find_by!(id: 'groups').data
    render json: kubernetes_groups
  end

end
