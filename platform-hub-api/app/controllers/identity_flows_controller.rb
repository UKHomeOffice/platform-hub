class IdentityFlowsController < AuthenticatedController

  skip_before_action :require_authentication, only: :callback

  # Note: only Github auth is supported for now
  # (the routing should handle this constraint)

  def start_auth_flow
    # Initial step to initiate an auth flow;
    # can only be accessed if already authenticated
    redirect_to gitHubIdentityService.authorize_url current_user
  end

  def callback
    # Callback from external service's OAuth2 flow

    code = params[:code]
    head :unprocessable_entity if code.blank?

    state = params[:state]
    head :unprocessable_entity if state.blank?

    user = nil
    begin
      user = gitHubIdentityService.connect_identity code, state
    rescue GitHubIdentityService::Errors::InvalidCallbackState => ex
      logger.error "Github identity flow callback was called with an invalid 'state' = #{state}"
      head :forbidden
    rescue GitHubIdentityService::Errors::NoAccessToken => ex
      logger.error "Github identity flow was unable to get an access token"
      head :forbidden
    rescue GitHubIdentityService::Errors::UserMismatch => ex
      logger.error "Github identity flow with mismatched users: the Github auth flow was carried out with a different user to the user assigned to an existing matching Github identity"
      head :forbidden
    end

    redirect_to Rails.application.config.app_base_url
  end

  protected

  def gitHubIdentityService
    @gitHubIdentityService ||= GitHubIdentityService.new(
      encryption_service: ShortLivedSymmetricEncryptionService.new(Rails.application.secrets.secret_key_base),
      client_id: Rails.application.secrets.github_client_id,
      client_secret: Rails.application.secrets.github_client_secret,
      app_base_url: Rails.application.config.app_base_url,
      callback_url: identity_flows_callback_path('github')
    )
  end

end
