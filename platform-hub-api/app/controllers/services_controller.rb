class ServicesController < ApiJsonController

  before_action :find_project
  before_action :find_service, only: [ :show, :update, :destroy ]

  # GET /projects/foo/services
  def index
    authorize! :read_services_in_project, @project

    services = @project.services.order(:name)
    render json: services
  end

  # GET /projects/foo/services/1
  def show
    authorize! :read_services_in_project, @project

    render json: @service
  end

  # POST /projects/foo/services
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
      render_model_errors service
    end
  end

  # PATCH/PUT /projects/foo/services/1
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
      render_model_errors @service
    end
  end

  # DELETE /projects/foo/services/1
  def destroy
    authorize! :administer_services_in_project, @project

    id = @service.id
    name = @service.name

    @service.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      associated: @project,
      comment: "User '#{current_user.email}' deleted service: '#{name}' (ID: #{id}) in project '#{@project.shortname}'"
    )

    head :no_content
  end

  private

  def find_project
    @project = Project.friendly.find params[:project_id]
  end

  def find_service
    @service = @project.services.find params[:id]
  end

  # Only allow a trusted parameter "white list" through.
  def service_params
    params.require(:service).permit(:name, :description)
  end
end
