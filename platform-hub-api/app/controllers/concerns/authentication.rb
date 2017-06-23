module Authentication
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token

  def require_authentication
    head :unauthorized unless authenticated?
  end

  def authenticated?
    current_user.present?
  end

  def current_user
    token, _ = token_and_options(request)

    return nil if token.blank?

    @current_user ||= create_or_fetch_user(token)
  end

  def create_or_fetch_user token
    # Important assumptions about the token:
    # - it is already verified by the auth proxy in front and we can trust the contents
    begin
      payload, _ = JWT.decode token, nil, false
    rescue JWT::ExpiredSignature
      return nil
    rescue => e
      logger.error "Failed to parse JWT token: #{token}. Error: #{e.message}"
      return nil
    end

    user = AuthUserService.get payload

    if user.present?
      user.touch :last_seen_at
    end

    user
  end

end
