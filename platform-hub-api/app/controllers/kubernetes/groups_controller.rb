class Kubernetes::GroupsController < ApiJsonController

  before_action :find_group, only: [ :show, :update, :destroy ]

  skip_authorization_check only: [ :index, :show ]
  authorize_resource class: KubernetesGroup, :except => [ :index, :show ]

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

  # DELETE /kubernetes/groups
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
