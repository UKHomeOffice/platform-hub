module AuthUserService
  extend self

  def get auth_token_payload
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

  def touch_and_update_main_identity user, payload
    user.with_lock do
      user.touch :last_seen_at
    end

    i = user.main_identity
    if i.present?
      i.with_lock do
        if i.external_id != payload['sub']
          i.update!(external_id: payload['sub'])
        end
      end
    end
  end

end
