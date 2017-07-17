class UsersController < ApiJsonController

  include GitHubOnboardingHelpers
  include UserActivation

  before_action :find_user, only: [
    :show,
    :make_admin,
    :revoke_admin,
    :activate,
    :deactivate,
    :onboard_github,
    :offboard_github
  ]

  authorize_resource

  # GET /users
  def index
    @users = User.order(:name)

    render json: @users
  end

  # GET /users/:id
  def show
    render json: @user
  end

  # GET /users/search/:q?include_deactivated=[true|false]
  def search
    scope = params[:include_deactivated] == 'true' ? User : User.active
    render json: scope.search(params[:q])
  end

  # POST /users/:id/make_admin
  def make_admin
    @user.make_admin!

    AuditService.log(
      context: audit_context,
      action: 'make_admin',
      auditable: @user
    )

    head :no_content
  end

  # POST /users/:id/revoke_admin
  def revoke_admin
    @user.revoke_admin!

    AuditService.log(
      context: audit_context,
      action: 'revoke_admin',
      auditable: @user
    )

    head :no_content
  end

  # POST /users/:id/activate
  def activate
    handle_user_activation_request
  end

  # POST /users/:id/deactivate
  def deactivate
    handle_user_deactivation_request
  end

  # POST /users/:id/onboard_github
  def onboard_github
    success = handle_onboard_github_request @user, audit_context
    head :no_content if success
  end

  # POST /users/:id/offboard_github
  def offboard_github
    success = handle_offboard_github_request @user, audit_context
    head :no_content if success
  end

  private

  def find_user
    @user = User.find params[:id]
  end
  
end
