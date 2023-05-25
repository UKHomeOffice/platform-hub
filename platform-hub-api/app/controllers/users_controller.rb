class UsersController < ApiJsonController

  include GitHubOnboardingHelpers
  include UserActivation

  before_action :find_user, only: [
    :show,
    :identities,
    :make_admin,
    :revoke_admin,
    :make_limited_admin,
    :revoke_limited_admin,
    :activate,
    :deactivate,
    :onboard_github,
    :offboard_github
  ]

  authorize_resource

  # GET /users
  def index
    @users = User.order(:name)

    paginate json: @users
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

  # GET /users/:id/identities
  def identities
    user_identity = @user.identities

    if current_user.id == @user.id
      user_identity.each do |item|
        if item["provider"] == "ecr"
          if item["credentials"]
            if item["credentials"]["access_id"]
              item["credentials"]["access_id"].gsub!(/\S/, '*')
            end
            if item["credentials"]["access_key"]
              item["credentials"]["access_key"].gsub!(/\S/, '*')
            end
          end
        end
      end
    end

    render json: user_identity
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

  # POST /users/:id/make_limited_admin
  def make_limited_admin
    @user.make_limited_admin!

    AuditService.log(
      context: audit_context,
      action: 'make_limited_admin',
      auditable: @user
    )

    head :no_content
  end

  # POST /users/:id/revoke_limited_admin
  def revoke_limited_admin
    @user.revoke_limited_admin!

    AuditService.log(
      context: audit_context,
      action: 'revoke_limited_admin',
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
