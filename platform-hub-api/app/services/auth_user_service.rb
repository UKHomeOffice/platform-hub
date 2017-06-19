module AuthUserService

  def self.get auth_token_payload
    return nil if auth_token_payload.blank? || auth_token_payload['email'].blank?

    email = auth_token_payload['email']

    retries = 3

    begin

      User.transaction do
        User.find_or_create_by!(email: email) do |u|
          u.id = auth_token_payload['sub'] || SecureRandom.uuid
          u.name = auth_token_payload['name']
          u.last_seen_at = DateTime.now

          u.identities.build(
            provider: 'keycloak',
            external_id: auth_token_payload['sub'],
            external_username: auth_token_payload['preferred_username'],
            external_name: auth_token_payload['name'],
            external_email: auth_token_payload['email'],
            data: auth_token_payload
          )
        end
      end

    rescue ActiveRecord::RecordNotUnique
      retry unless (retries -= 1).zero?
    end

  end

end
