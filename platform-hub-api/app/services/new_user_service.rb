class NewUserService

  def create auth_token_payload
    return nil if auth_token_payload.blank?

    user = User.new

    user.id = auth_token_payload['sub']
    user.name = auth_token_payload['name']
    user.email = auth_token_payload['email']

    user.identities.build(
      provider: 'keycloak',
      external_id: auth_token_payload['sub'],
      external_username: auth_token_payload['preferred_username'],
      external_name: auth_token_payload['name'],
      external_email: auth_token_payload['email'],
      data: auth_token_payload
    )

    user.last_seen_at = DateTime.now

    user.save!

    user
  end

end
