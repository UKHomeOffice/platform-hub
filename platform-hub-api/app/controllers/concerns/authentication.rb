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

  private

  def create_or_fetch_user token
    # Important assumptions about the token:
    # - it is already verified by the auth proxy in front
    # - expiry has already been checked by the auth proxy in front (TODO: perhaps recheck here)
    begin
      payload, _ = JWT.decode(token, nil, false)
    rescue => e
      logger.error "Failed to parse JWT token: #{token}. Error: #{e.message}"
      return nil
    end

    return nil if payload.blank? || payload['sub'].blank?

    id = payload['sub']

    user = User.find_by_id(id)

    if user.blank?
      user = NewUserService.new.create payload
    else
      user.touch(:last_seen_at)
    end

    user
  end

end
