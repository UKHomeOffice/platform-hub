class Kubernetes::ClustersController < ApiJsonController

  before_action :load_kubernetes_clusters_hash_record

  # GET /kubernetes/clusters
  def index
    authorize! :read, :kubernetes_clusters
    render json: @kubernetes_clusters.data.map {|c| c.with_indifferent_access.slice(:id, :description)}
  end

  # PATCH/PUT /kubernetes/clusters/:id
  def create_or_update
    authorize! :manage, :kubernetes_clusters

    data = cluster_params.to_h
    data[:id] = params[:id]  # ID in URL takes precedence

    Kubernetes::ClusterService.create_or_update data

    AuditService.log(
      context: audit_context,
      action: 'update_kubernetes_cluster',
      data: { id: params[:id] },
      comment: "Kubernetes cluster '#{params[:id]}' created or updated by #{current_user.email}"
    )

    head :no_content
  end

  private

  def load_kubernetes_clusters_hash_record
    @kubernetes_clusters = HashRecord.kubernetes.find_or_create_by!(id: 'clusters') do |r|
      r.data = []
    end
  end

  def cluster_params
    params.require(:cluster).permit(
      :id,
      :description,
      :s3_region,
      :s3_bucket_name,
      :s3_access_key_id,
      :s3_secret_access_key,
      :object_key
    )
  end

end
