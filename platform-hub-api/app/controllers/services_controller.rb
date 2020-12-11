class ServicesController < ApiJsonController

  include KubernetesGroupsSubCollection
  include KubernetesTokensManagement

  before_action :find_project

  before_action :find_service, only: [
    :show,
    :update,
    :destroy,
    :kubernetes_groups,
    :kubernetes_robot_tokens,
    :show_kubernetes_robot_token,
    :create_kubernetes_robot_token,
    :update_kubernetes_robot_token,
    :destroy_kubernetes_robot_token
  ]

  before_action :find_robot_token, only: [
    :show_kubernetes_robot_token,
    :update_kubernetes_robot_token,
    :destroy_kubernetes_robot_token
  ]

  # GET /projects/:project_id/services
  def index
    authorize! :read_services_in_project, @project

    services = @project.services.order(:name)
    render json: services
  end

  # GET /projects/:project_id/services/:id
  def show
    authorize! :read_services_in_project, @project

    render json: @service

  end

  # POST /projects/:project_id/services
  def create
    authorize! :administer_services_in_project, @project

    service = @project.services.new(service_params)

    if service.save
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: service
      )

      render json: service, status: :created
    else
      render_model_errors service.errors
    end
  end

  # PATCH/PUT /projects/:project_id/services/:id
  def update
    authorize! :administer_services_in_project, @project

    if @service.update(service_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @service
      )

      render json: @service
    else
      render_model_errors @service.errors
    end
  end

  # DELETE /projects/:project_id/services/:id
  def destroy
    authorize! :administer_services_in_project, @project

    id = @service.id
    name = @service.name

    @service.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      auditable: @service,
      associated: @project,
      comment: "User '#{current_user.email}' deleted service: '#{name}' (ID: #{id}) in project '#{@project.shortname}'"
    )

    head :no_content
  end

  # GET /projects/:project_id/services/:id/kubernetes_groups
  def kubernetes_groups
    authorize! :read_resources_in_services_in_project, @project

    kubernetes_groups_sub_collection @service, params[:target]
  end

  # GET /projects/:project_id/services/:id/kubernetes_robot_tokens
  def kubernetes_robot_tokens
    authorize! :read_resources_in_services_in_project, @project

    render json: @service.kubernetes_robot_tokens.order(:name)
  end

  # GET /projects/:project_id/services/:id/kubernetes_robot_tokens/:token_id
  def show_kubernetes_robot_token
    authorize! :read_resources_in_services_in_project, @project

    render json: @token
  end

  # POST /projects/:project_id/services/:id/kubernetes_robot_tokens
  def create_kubernetes_robot_token
    authorize! :administer_resources_in_services_in_project, @project

    token_params = params.require(:robot_token)
    token_params[:service_id] = @service.id
    create_kubernetes_token 'robot', token_params
  end

  # PATCH /projects/:project_id/services/:id/kubernetes_robot_tokens/:token_id
  def update_kubernetes_robot_token
    authorize! :administer_resources_in_services_in_project, @project

    token_params = params.require(:robot_token)
    update_kubernetes_token 'robot', @token, token_params
  end

  # DELETE /projects/:project_id/services/:id/kubernetes_robot_tokens/:token_id
  def destroy_kubernetes_robot_token
    authorize! :administer_resources_in_services_in_project, @project

    destroy_kubernetes_token @token
  end

  private

  def find_project
    @project = Project.friendly.find params[:project_id]
  end

  def find_service
    @service = @project.services.find params[:id]
  end

  def find_robot_token
    @token = @service.kubernetes_robot_tokens.find params[:token_id]
  end

  # Only allow a trusted parameter "white list" through.
  def service_params
    params.require(:service).permit(:name, :description)
  end
end
