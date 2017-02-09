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

    AuditService.log(
      context: audit_context,
      action: 'create',
      auditable: @project
    )

    if @project.save
      render json: @project, status: :created
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /projects/:id
  def update
    if @project.update(project_params)
      AuditService.log(
        context: audit_context,
        action: 'update',
        auditable: @project
      )

      render json: @project
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  # DELETE /projects/:id
  def destroy
    shortname = @project.shortname

    @project.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      comment: "User '#{current_user.email}' deleted project: #{shortname}"
    )

    head :no_content
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

      AuditService.log(
        context: audit_context,
        action: 'add_membership',
        auditable: @project,
        associated: @membership.user,
        data: {
          member_id: @membership.user.id,
          member_name: @membership.user.name,
          member_email: @membership.user.email
        }
      )
    end
    render json: @membership, serializer: ProjectMembershipSerializer
  end

  # DELETE /projects/:id/memberships/:user_id
  def remove_membership
    @project.members.destroy(@user)

    AuditService.log(
      context: audit_context,
      action: 'remove_membership',
      auditable: @project,
      associated: @user,
      data: {
        member_id: @user.id,
        member_name: @user.name,
        member_email: @user.email
      }
    )

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
