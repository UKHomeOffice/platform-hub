class UsersController < ApiJsonController

  include AgentsInitializer

  before_action :find_user, only: [ :show, :make_admin, :revoke_admin, :onboard_github, :offboard_github ]

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

  # GET /users/search/:q
  def search
    render json: User.search(params[:q])
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

  # POST /users/:id/onboard_github
  def onboard_github
    handle_github_agent_request :onboard
  end

  # POST /users/:id/offboard_github
  def offboard_github
    handle_github_agent_request :offboard
  end

  private

  def find_user
    @user = User.find params[:id]
  end

  def handle_github_agent_request agent_action
    begin
      success = git_hub_agent_service.send "#{agent_action}_user", @user

      if success
        AuditService.log(
          context: audit_context,
          action: action_name,
          auditable: @user,
        )
        head :no_content
      else
        render_error "Failed to #{agent_action} the user to GitHub - the GitHub API may be down", :service_unavailable
      end
    rescue Agents::GitHubAgentService::Errors::IdentityMissing
      render_error 'User does not have a GitHub identity connected yet', :bad_request
    rescue => e
      logger.error "Failed to call the GitHub API during the #{action_name} action. Exception type: #{e.class.name}. Message: #{e.message}"
      render_error 'Unknown error whilst calling the GitHub API', :service_unavailable
    end
  end

end
