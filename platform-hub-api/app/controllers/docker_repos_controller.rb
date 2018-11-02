class DockerReposController < ApiJsonController

  before_action :find_project

  before_action :find_docker_repo, only: [ :destroy ]

  # GET /projects/foo/docker_repos
  def index
    authorize! :read_docker_repos_in_project, @project

    docker_repos = @project.docker_repos.order(:name)
    render json: docker_repos
  end

  # POST /projects/foo/docker_repos
  def create
    authorize! :administer_docker_repos_in_project, @project

    service = @project.services.find params[:service_id]

    docker_repo = service.docker_repos.new(docker_repo_params)

    if docker_repo.save
      # TODO post to queue

      AuditService.log(
        context: audit_context,
        action: 'request_create',
        auditable: docker_repo
      )

      render json: docker_repo, status: :created
    else
      render_model_errors docker_repo
    end
  end

  # DELETE /projects/foo/docker_repos/1
  def destroy
    authorize! :administer_docker_repos_in_project, @project

    id = @docker_repo.id
    name = @docker_repo.name
    service = @docker_repo.service

    @docker_repo.update! status: :deleting

    # TODO post to queue

    AuditService.log(
      context: audit_context,
      action: 'request_delete',
      auditable: @docker_repo,
      associated: service,
      comment: "User '#{current_user.email}' has requested deletion of Docker repo: '#{name}' (ID: #{id}) in project '#{@project.shortname}'"
    )

    head :no_content
  end

  private

  def find_project
    @project = Project.friendly.find params[:project_id]
  end

  def find_docker_repo
    @docker_repo = @project.docker_repos.find params[:id]
  end

  # Only allow a trusted parameter "white list" through.
  def docker_repo_params
    params.require(:docker_repo).permit(:name, :description)
  end
end
