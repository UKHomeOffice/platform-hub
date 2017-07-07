class Kubernetes::ClustersController < ApiJsonController

  before_action :load_kubernetes_clusters_hash_record

  # GET /kubernetes_clusters
  def index
    authorize! :read, :kubernetes_clusters
    render json: @kubernetes_clusters.data.map {|c| c.with_indifferent_access.slice(:id, :description)}
  end

  private

  def load_kubernetes_clusters_hash_record
    @kubernetes_clusters = HashRecord.kubernetes.find_or_create_by!(id: 'clusters') do |r|
      r.data = []
    end
  end

end
