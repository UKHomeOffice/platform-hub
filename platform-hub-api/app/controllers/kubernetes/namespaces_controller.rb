class Kubernetes::NamespacesController < ApiJsonController

  before_action :find_namespace, only: [ :show, :update, :destroy ]

  authorize_resource class: KubernetesNamespace

  # GET /kubernetes/namespaces
  def index
    scope = if params[:service_id]
      Service.find(params[:service_id]).kubernetes_namespaces
    elsif params[:cluster_name]
      KubernetesCluster.friendly.find(params[:cluster_name]).namespaces
    else
      KubernetesNamespace.all
    end

    namespaces = scope.order(:name)

    paginate json: namespaces
  end

  # GET /kubernetes/namespaces/:id
  def show
    render json: @namespace
  end

  # POST /kubernetes/namespaces
  def create
    params = namespace_create_params

    service = Service.find params[:service_id]
    cluster = KubernetesCluster.friendly.find params[:cluster_name]

    namespace = KubernetesNamespace.new(
      service: service,
      cluster: cluster,
      name: params[:name],
      description: params[:description]
    )

    if namespace.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: namespace
      )

      render json: namespace, status: :created
    else
      render_model_errors namespace.errors
    end
  end

  # PATCH/PUT /kubernetes/namespaces/:id
  def update
    if @namespace.update(namespace_update_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @namespace
      )

      render json: @namespace
    else
      render_model_errors @namespace.errors
    end
  end

  # DELETE /kubernetes/namespaces/:id
  def destroy
    @namespace.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @namespace,
      comment: "User '#{current_user.email}' deleted kubernetes namespace: '#{@namespace.name}' (ID: #{@namespace.id})"
    )

    head :no_content
  end

  private

  def find_namespace
    @namespace = KubernetesNamespace.find params[:id]
  end

  def namespace_create_params
    params.require(:namespace).permit(:service_id, :cluster_name, :name, :description)
  end

  def namespace_update_params
    params.require(:namespace).permit(:description)
  end

end
