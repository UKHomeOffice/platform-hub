class DockerReposController < ApiJsonController

  before_action :find_project

  before_action :find_docker_repo, only: [ :destroy, :update_access ]

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

    docker_repo = DockerRepoLifecycleService.new.request_create(
      service,
      docker_repo_params,
      audit_context,
    )

    if docker_repo.errors.empty?
      render json: docker_repo, status: :created
    else
      render_model_errors docker_repo.errors
    end
  end

  # DELETE /projects/foo/docker_repos/1
  def destroy
    authorize! :administer_docker_repos_in_project, @project

    DockerRepoLifecycleService.new.request_delete!(
      @docker_repo,
      audit_context,
    )

    head :no_content
  end

  # PUT /projects/foo/docker_repos/1/access
  def update_access
    authorize! :administer_docker_repos_in_project, @project

    robots = params.fetch(:robots).map { |r| r.permit(:username).to_h }
    users = params.fetch(:users).map { |r| r.permit(:username, :writable).to_h }

    DockerRepoAccessPolicyService.new(@docker_repo).request_update!(
      robots,
      users,
      audit_context,
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
