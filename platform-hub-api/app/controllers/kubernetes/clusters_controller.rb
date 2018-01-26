class Kubernetes::ClustersController < ApiJsonController

  before_action :find_cluster, only: [
    :show,
    :update,
    :allocate,
    :allocations,
    :robot_tokens,
    :user_tokens
  ]

  authorize_resource class: KubernetesCluster

  # GET /kubernetes/clusters
  def index
    clusters = KubernetesCluster.order(:name)
    render json: clusters, each_serializer: KubernetesClusterSerializer
  end

  # GET /kubernetes/clusters/:id
  def show
    render json: @cluster
  end

  # POST /kubernetes/clusters
  def create
    cluster = KubernetesCluster.new(cluster_params)

    if cluster.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: cluster
      )
      render json: cluster, status: :created
    else
      render_model_errors cluster.errors
    end
  end

  # PATCH/PUT /kubernetes/clusters/:id
  def update
    if @cluster.update(cluster_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @cluster
      )

      render json: @cluster
    else
      render_model_errors @cluster.errors
    end
  end

  # POST /kubernetes/clusters/:id/allocate
  def allocate
    project = Project.friendly.find(params.require(:project_id))

    allocation = Allocation.new(
      allocatable: @cluster,
      allocation_receivable: project
    )

    if allocation.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: allocation,
        data: {
          allocatable_type: @cluster.class.name,
          allocatable_id: @cluster.id,
          allocatable_descriptor: @cluster.name
        }
      )

      head :no_content
    else
      render_model_errors allocation.errors
    end
  end

  # GET /kubernetes/clusters/:id/allocations
  def allocations
    allocations = Allocation.by_allocatable @cluster
    render json: allocations
  end

  # GET /kubernetes/clusters/:id/robot_tokens
  def robot_tokens
    tokens = KubernetesToken.robot.by_cluster(@cluster).order(updated_at: :desc)
    paginate json: tokens
  end

  # GET /kubernetes/clusters/:id/user_tokens
  def user_tokens
    tokens = KubernetesToken.user.by_cluster(@cluster).order(updated_at: :desc)
    paginate json: tokens
  end

  private

  def find_cluster
    @cluster = KubernetesCluster.friendly.find params[:id]
  end

  def cluster_params
    params.require(:cluster).permit(
      :name,
      :description,
      :aws_account_id,
      :s3_region,
      :s3_bucket_name,
      :s3_access_key_id,
      :s3_secret_access_key,
      :s3_object_key,
      :api_url,
      :ca_cert_encoded
    )
  end

end
