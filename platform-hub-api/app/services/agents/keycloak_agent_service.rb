module Agents
  class KeycloakAgentService

    module Errors
      class KeycloakIdentityMissing < StandardError; end
      class KeycloakUserRepresentationMissing < StandardError; end
      class KeycloakUserRepresentationUpdateFailed < StandardError; end
      class KeycloakAccessTokenRequestFailed < StandardError; end
      class KeycloakAccessTokenExpired < StandardError; end
    end

    def initialize base_url:, realm:, client_id:, client_secret:, username:, password:
      @base_url = base_url
      @realm = realm
      @client_id = client_id
      @client_secret = client_secret
      @username = username
      @password = password
    end

    def client
      @client ||= Faraday.new @base_url
    end

    def bearer_token
      if @token.present?
        begin
          JWT.decode @token, nil, false
          return @token
        rescue JWT::ExpiredSignature
          @token = nil
        end
      end

      begin
        response = client.post "/auth/realms/#{@realm}/protocol/openid-connect/token",
          {
            client_id: @client_id,
            client_secret: @client_secret,
            username: @username,
            password: @password,
            grant_type: 'password'
          }
      rescue => e
        Rails.logger.error "Couldn't obtain access token from Keycloak: #{e.class} - #{e.message}"
        raise Errors::KeycloakAccessTokenRequestFailed
      end

      if response.success?
        Rails.logger.info 'Obtained access token from Keycloak.'
        @token = JSON.parse(response.body)['access_token']
      else
        Rails.logger.error "Couldn't obtain access token from Keycloak. Response: #{response.body}"
        raise Errors::KeycloakAccessTokenRequestFailed
      end
    end

    def deactivate_user(user)
      update_enabled_state(user, false)
    end

    def activate_user(user)
      update_enabled_state(user, true)
    end

    def update_enabled_state(user, state)
      retries ||= 0
      representation = get_user_representation(user)
      representation['enabled'] = state
      update_user(representation)
    rescue Errors::KeycloakAccessTokenExpired
      retry if (retries += 1) < 3
    end

    private

    def get_user_representation(user)
      keycloak_identity = user.identity(:keycloak)
      user_id = keycloak_identity.try(:external_id)

      raise Errors::KeycloakIdentityMissing if user_id.nil?

      begin
        response = client.get "/auth/admin/realms/#{@realm}/users/#{user_id}",
          {},
          {Authorization: "Bearer #{bearer_token}"}
      rescue => e
        Rails.logger.error "Couldn't get user representation from Keycloak: #{e.class} - #{e.message}"
        raise Errors::KeycloakUserRepresentationMissing
      end

      handle response

      if response.success?
        JSON.parse(response.body)
      else
        Rails.logger.error "Couldn't get user representation from Keycloak. Response: #{response.body}"
        raise Errors::KeycloakUserRepresentationMissing
      end
    end

    def update_user(representation = {})
      user_id = representation['id']

      if user_id.nil?
        Rails.logger.error 'Keycloak user representation missing and will not be updated.'
        raise Errors::KeycloakUserRepresentationMissing
      end

      begin
        response = client.put "/auth/admin/realms/#{@realm}/users/#{user_id}",
          representation.to_json,
          {
            'Authorization': "Bearer #{bearer_token}",
            'Content-Type': 'application/json'
          }
      rescue => e
        Rails.logger.error "Couldn't update user representation in Keycloak: #{e.class} - #{e.message}"
        raise Errors::KeycloakUserRepresentationUpdateFailed
      end

      handle response

      if response.success?
        Rails.logger.info 'User representation updated in Keycloak!'
        representation
      else
        Rails.logger.error "User representation hasn't been updated in Keycloak! Response: #{response.body}"
        raise Errors::KeycloakUserRepresentationUpdateFailed
      end
    end

    def handle(response)
      if response.status == 401 && response.body == 'Bearer' # Auth token expired
        Rails.logger.info 'Keycloak agent Bearer token expired.'
        raise Errors::KeycloakAccessTokenExpired
      end
    end

  end
end
