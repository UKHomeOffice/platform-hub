class IdentityFlowsController < AuthenticatedController

  skip_before_action :require_authentication, only: :callback

  # Note: only Github auth is supported for now
  # (the routing should handle this constraint)

  def start_auth_flow
    # Initial step to initiate an auth flow;
    # can only be accessed if already authenticated
    redirect_to git_hub_identity_service.authorize_url current_user
  end

  def callback
    # Callback from external service's OAuth2 flow

    code = params[:code]
    if code.blank?
      head :unprocessable_entity and return
    end

    state = params[:state]
    if state.blank?
      head :unprocessable_entity and return
    end

    begin
      identity = git_hub_identity_service.connect_identity code, state

      AuditService.log(
        context: audit_context,
        action: 'connect_identity',
        auditable: identity,
        comment: "GitHub identity connected for user '#{identity.user.email}' - GitHub username: #{identity.external_username}"
      )
    rescue GitHubIdentityService::Errors::InvalidCallbackState => ex
      logger.error "Github identity flow callback was called with an invalid 'state' = #{state}"
      head :forbidden and return
    rescue GitHubIdentityService::Errors::NoAccessToken => ex
      logger.error "Github identity flow was unable to get an access token"
      head :forbidden and return
    rescue GitHubIdentityService::Errors::UserMismatch => ex
      logger.error "Github identity flow with mismatched users: the Github auth flow was carried out with a different user to the user assigned to an existing matching Github identity"
      head :forbidden and return
    end

    redirect_to Rails.application.config.app_base_url
  end

  protected

  def git_hub_identity_service
    @git_hub_identity_service ||= GitHubIdentityService.new(
      encryption_service: ENCRYPTOR,
      client_id: Rails.application.secrets.github_client_id,
      client_secret: Rails.application.secrets.github_client_secret,
      app_base_url: Rails.application.config.app_base_url,
      callback_url: identity_flows_callback_path('github')
    )
  end

end
