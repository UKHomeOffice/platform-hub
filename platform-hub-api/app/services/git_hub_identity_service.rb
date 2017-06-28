class GitHubIdentityService

  def initialize encryption_service:, client_id:, client_secret:, app_base_url:, callback_url:
    @encryption_service = encryption_service
    @client_id = client_id
    @client_secret = client_secret
    @app_base_url = app_base_url
    @callback_url = callback_url
  end

  def authorize_url existing_user
    Octokit::Client.new.authorize_url(
      @client_id,
      {
        scope: '',
        redirect_uri: "#{@app_base_url}/api/#{@callback_url}",
        state: Base64.encode64(@encryption_service.encrypt(existing_user.id))
      }
    )
  end

  def connect_identity code, state
    user_id = @encryption_service.decrypt(Base64.decode64(state))
    user = User.find_by_id(user_id)

    if user.blank?
      raise Errors::InvalidCallbackState
    end

    result = Octokit.exchange_code_for_token(code, @client_id, @client_secret)
    access_token = result[:access_token]

    if access_token.blank?
      raise Errors::NoAccessToken
    end

    github_client = Octokit::Client.new
    github_client.access_token = access_token
    github_user = github_client.user

    identity = Identity.find_by(external_id: github_user.id)
    if identity.blank?
      identity = user.identities.create!(
        provider: 'github',
        external_id: github_user.id,
        external_username: github_user.login,
        external_name: github_user.name,
        external_email: github_user.email,
        data: github_user.to_json
      )
    else
      # Check for user mismatch
      if identity.user_id != user.id
        raise Errors::UserMismatch
      end
    end

    identity
  end


  module Errors
    class InvalidCallbackState < StandardError
    end

    class NoAccessToken < StandardError
    end

    class UserMismatch < StandardError
    end
  end

end
