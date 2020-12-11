class ProjectsController < ApiJsonController

  include KubernetesGroupsSubCollection
  include KubernetesTokensManagement

  before_action :find_project, only: [
    :show,
    :update,
    :destroy,
    :memberships,
    :add_membership,
    :remove_membership,
    :set_role,
    :unset_role,
    :role_check,
    :kubernetes_clusters,
    :kubernetes_groups,
    :kubernetes_user_tokens,
    :show_kubernetes_user_token,
    :create_kubernetes_user_token,
    :update_kubernetes_user_token,
    :destroy_kubernetes_user_token,
    :bills
  ]

  before_action :find_user, only: [
    :add_membership,
    :remove_membership,
    :set_role,
    :unset_role
  ]

  before_action :find_user_token, only: [
    :show_kubernetes_user_token,
    :update_kubernetes_user_token,
    :destroy_kubernetes_user_token
  ]

  skip_authorization_check only: [
    :index,
    :show,
    :memberships,
    :role_check
  ]

  authorize_resource except: [
    :index,
    :show,
    :memberships,
    :role_check,
    :kubernetes_clusters,
    :kubernetes_groups,
    :kubernetes_user_tokens,
    :show_kubernetes_user_token,
    :create_kubernetes_user_token,
    :update_kubernetes_user_token,
    :destroy_kubernetes_user_token
  ]

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
      AuditService.log(
        context: audit_context,
        action: 'create',
        auditable: @project
      )

      render json: @project, status: :created
    else
      render_model_errors @project.errors
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
      render_model_errors @project.errors
    end
  end

  # DELETE /projects/:id
  def destroy
    id = @project.id
    shortname = @project.shortname

    @project.destroy

    AuditService.log(
      context: audit_context,
      action: 'destroy',
      comment: "User '#{current_user.email}' deleted project: '#{shortname}' (ID: #{id})"
    )

    head :no_content
  end

  # GET /projects/:id/memberships
  def memberships
    memberships = @project.memberships_ordered_by_users_name
    render json: memberships, each_serializer: ProjectMembershipSerializer
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

  # GET /projects/:id/memberships/role_check/:role
  def role_check
    case params[:role]
    when 'admin'
      is_admin = ProjectMembershipsService.is_user_an_admin_of_project?(@project.id, current_user.id)
      render json: { result: is_admin }
    else
      not_found_error
    end
  end

  # PUT /projects/:id/memberships/:user_id/role/:role
  def set_role
    role = params[:role]
    handle_role_change role: role
  end

  # DELETE /projects/:id/memberships/:user_id/role/:role
  def unset_role
    handle_role_change role: nil
  end

  # GET /projects/:id/kubernetes_clusters
  def kubernetes_clusters
    authorize! :read_resources_in_project, @project

    render json: @project.kubernetes_clusters.order(:name)
  end

  # GET /projects/:id/kubernetes_groups
  def kubernetes_groups
    authorize! :read_resources_in_project, @project

    kubernetes_groups_sub_collection @project, params[:target]
  end

  # GET /projects/:id/kubernetes_user_tokens
  def kubernetes_user_tokens
    authorize! :administer_projects, @project

    Kubernetes::TokensExpirerJobTriggerService.trigger

    render json: @project.kubernetes_user_tokens.order(:name)
  end

  # GET /projects/:id/kubernetes_user_tokens/:token_id
  def show_kubernetes_user_token
    authorize! :administer_projects, @project

    render json: @token
  end

  # POST /projects/:id/kubernetes_user_tokens
  def create_kubernetes_user_token
    authorize! :administer_projects, @project

    token_params = params.require(:user_token)
    token_params[:project_id] = @project.id
    create_kubernetes_token 'user', token_params
  end

  # PATCH /projects/:id/kubernetes_user_tokens/:token_id
  def update_kubernetes_user_token
    authorize! :administer_projects, @project

    token_params = params.require(:user_token)
    update_kubernetes_token 'user', @token, token_params
  end

  # DELETE /projects/:id/kubernetes_user_tokens/:token_id
  def destroy_kubernetes_user_token
    authorize! :administer_projects, @project

    destroy_kubernetes_token @token
  end

  # GET /projects/:id/bills
  def bills
    bills = Costs::ProjectBillsQueryService.fetch @project.id
    render json: bills
  end

  private

  def find_project
    @project = Project.friendly.find params[:id]
  end

  def find_user
    @user = User.find params[:user_id]
  end

  def find_user_token
    @token = @project.kubernetes_user_tokens.find params[:token_id]
  end

  # Only allow a trusted parameter "white list" through
  def project_params
    params.require(:project).permit(:shortname, :name, :description, :cost_centre_code)
  end

  # Currently we only have the ability to store one role per membership,
  # so this method only takes in a role value OR `nil`, and essentially toggles
  # the `role` field on the membership.
  def handle_role_change role:
    membership = @project.memberships.where(user_id: @user.id).first

    if membership
      previous_role = membership.role

      if membership.update(role: role)
        AuditService.log(
          context: audit_context,
          action: action_name,
          auditable: @project,
          associated: membership.user,
          data: {
            previous_role: previous_role,
            new_role: role,
            member_id: membership.user.id,
            member_name: membership.user.name,
            member_email: membership.user.email
          }
        )

        render json: membership, serializer: ProjectMembershipSerializer
      else
        render_model_errors membership.errors
      end
    else
      render_error 'User is not a team member of the project', :bad_request
    end
  end

end
