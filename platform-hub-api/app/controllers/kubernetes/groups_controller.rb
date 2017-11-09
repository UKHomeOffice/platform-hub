class Kubernetes::GroupsController < ApiJsonController

  before_action :find_group, only: [ :show, :update, :destroy, :allocate, :allocations ]

  authorize_resource class: KubernetesGroup

  # GET /kubernetes/groups
  def index
    groups = KubernetesGroup.order(:name)
    render json: groups
  end

  # GET /kubernetes/groups/:id
  def show
    render json: @group
  end

  # POST /kubernetes/groups
  def create
    group = KubernetesGroup.new(group_params)

    if group.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: group
      )

      render json: group, status: :created
    else
      render_model_errors group.errors
    end
  end

  # PATCH/PUT /kubernetes/groups/:id
  def update
    if @group.update(group_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @group
      )

      render json: @group
    else
      render_model_errors @group.errors
    end
  end

  # DELETE /kubernetes/groups/:id
  def destroy
    id = @group.id
    name = @group.name

    @group.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @group,
      comment: "User '#{current_user.email}' deleted kubernetes group: '#{name}' (ID: #{id})"
    )

    head :no_content
  end

  # GET /kubernetes/groups/privileged
  def privileged
    groups = KubernetesGroup.privileged.order(:name)
    render json: groups
  end

  # POST /kubernetes/groups/:id/allocate
  def allocate
    project = Project.friendly.find(params.require(:project_id))

    service_id = params[:service_id]
    service = nil
    if service_id
      service = project.services.find(service_id)
    end

    # If no service is specified, allocate to the project
    receivable = service || project

    allocation = Allocation.new(
      allocatable: @group,
      allocation_receivable: receivable
    )

    if allocation.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: allocation,
        data: {
          allocatable_type: @group.class.name,
          allocatable_id: @group.id,
          allocatable_descriptor: @group.name
        }
      )

      head :no_content
    else
      render_model_errors allocation.errors
    end
  end

  # GET /kubernetes/groups/:id/allocations
  def allocations
    allocations = Allocation.by_allocatable @group
    render json: allocations
  end

  private

  def find_group
    @group = KubernetesGroup.friendly.find params[:id]
  end

  # Only allow a trusted parameter "white list" through
  def group_params
    # Need to set a default for `restricted_to_clusters` to handle `nil` values
    # for the param in the permit below.
    params[:group][:restricted_to_clusters] ||= []

    params.require(:group).permit(
      :name,
      :kind,
      :target,
      :description,
      :is_privileged,
      restricted_to_clusters: []
    )
  end

end
