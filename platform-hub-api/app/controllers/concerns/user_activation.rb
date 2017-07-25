module UserActivation
  extend ActiveSupport::Concern

  def handle_user_activation_request
    handle_action :activate
  end

  def handle_user_deactivation_request
    handle_action :deactivate
  end

  private

  def handle_action action
    unless [:activate, :deactivate].include?(action.to_sym)
      Rails.logger.error "Action `#{action}` not supported"
      render_error 'User status change failed', :unprocessable_entity and return
    end

    case action.to_sym
    when :activate
      @user.with_lock do
        UserActivationService.activate! @user
      end
    when :deactivate
      @user.with_lock do
        UserActivationService.deactivate! @user
      end
    end

    AuditService.log(
      context: audit_context,
      action: action.to_s,
      auditable: @user
    )

    head :no_content
  rescue Agents::KeycloakAgentService::Errors::KeycloakIdentityMissing
    message = 'User keycloak identity missing'
    Rails.logger.error message
    render_error message, :unprocessable_entity and return
  rescue Agents::KeycloakAgentService::Errors::KeycloakUserRepresentationMissing
    message = 'Could not retrieve user representation from Keycloak'
    Rails.logger.error message
    render_error message, :unprocessable_entity and return
  rescue Agents::KeycloakAgentService::Errors::KeycloakUserRepresentationUpdateFailed
    message = 'Could not update user representation in Keycloak'
    Rails.logger.error message
    render_error message, :unprocessable_entity and return
  rescue Agents::KeycloakAgentService::Errors::KeycloakAccessTokenRequestFailed
    message = 'Could not obtain Keycloak auth token'
    Rails.logger.error message
    render_error message, :unprocessable_entity and return
  rescue => e
    Rails.logger.error "User status change failed - #{e.class}: #{e.message}"
    render_error 'User status change failed', :unprocessable_entity and return
  end

end
