class ProjectsController < ApiJsonController

  before_action :find_project, only: [ :show, :update, :destroy, :memberships, :add_membership, :remove_membership ]
  before_action :find_user, only: [ :add_membership, :remove_membership ]

  skip_authorization_check :only => [ :index, :show, :memberships ]
  authorize_resource except: [ :index, :show, :memberships ]

  # GET /projects
  def index
    @projects = Project.order(:shortname)

    render json: @projects
  end

  # GET /projects/:id
  def show
    render json: @project
  end

  # POST /projects
  def create
    @project = Project.new(project_params)

    if @project.save
      render json: @project, status: :created
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /projects/:id
  def update
    if @project.update(project_params)
      render json: @project
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # DELETE /projects/:id
  def destroy
    @project.destroy
  end

  # GET /projects/:id/memberships
  def memberships
    render json: @project.memberships, each_serializer: ProjectMembershipSerializer
  end

  # PUT /projects/:id/memberships/:user_id
  def add_membership
    if @project.memberships.exists?(user_id: @user.id)
      @membership = @project.memberships.where(user_id: @user.id).first
    else
      @membership = @project.memberships.create! user: @user
    end
    render json: @membership, serializer: ProjectMembershipSerializer
  end

  # DELETE /projects/:id/memberships/:user_id
  def remove_membership
    @project.members.destroy(@user)
    head :no_content
  end

  private

  def find_project
    @project = Project.friendly.find params[:id]
  end

  def find_user
    @user = User.find params[:user_id]
  end

  # Only allow a trusted parameter "white list" through
  def project_params
    params.require(:project).permit(:shortname, :name, :description)
  end
end
