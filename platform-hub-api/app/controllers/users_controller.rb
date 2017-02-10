class UsersController < ApiJsonController

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
      success = gitHubAgentService.send "#{agent_action}_user", @user

      if success
        AuditService.log(
          context: audit_context,
          action: action_name,
          auditable: @user,
        )
        head :no_content
      else
        render_error "Failed to Github #{agent_action} the user - the GitHub API may be down", :service_unavailable
      end
    rescue Agents::GitHubAgentService::Errors::IdentityMissing
      render_error 'User does not have a GitHub identity connected yet', :bad_request
    end
  end

  def gitHubAgentService
    @gitHubAgentService ||= Agents::GitHubAgentService.new(
      token: Rails.application.secrets.agent_github_token,
      org: Rails.application.secrets.agent_github_org,
      main_team_id: Rails.application.secrets.agent_github_org_main_team_id
    )
  end

end
