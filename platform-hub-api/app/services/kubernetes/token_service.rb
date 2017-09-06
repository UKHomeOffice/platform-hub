module Kubernetes
  module TokenService
    extend self

    def tokens_from_identity_data(data)
      data.with_indifferent_access[:tokens].collect do |t|
        KubernetesToken.from_data(t)
      end
    end

    def create_or_update_token(data, identity_id, cluster, groups, token = nil)
      tokens = tokens_from_identity_data(data)
      existing_token = tokens.find {|t| t.cluster == cluster}

      if existing_token
        existing_token.token = token_value(token) if token.present? # set token only if provided
        existing_token.groups = cleanup_groups(groups)
        [tokens, existing_token]
      else
        new_token = KubernetesToken.new(
          identity_id: identity_id,
          cluster: cluster,
          groups: cleanup_groups(groups),
          token: token_value(token),
          uid: generate_secure_random
        )
        tokens << new_token
        [tokens, new_token]
      end
    end

    def delete_token(data, cluster)
      tokens = tokens_from_identity_data(data)
      deleted_token = tokens.delete_at(tokens.find_index { |t| t.cluster == cluster })
      [tokens, deleted_token]
    end

    def generate_secure_random
      SecureRandom.uuid
    end

    def cleanup_groups(groups)
      if groups.is_a? String
        groups.split(',').map(&:strip).reject(&:blank?).uniq
      else
        groups
      end
    end

    def token_value(token = nil)
      if token.nil?
        generate_secure_random
      else
        decrypted_token = ENCRYPTOR.decrypt(token)
        decrypted_token.nil? ? token : decrypted_token
      end
    end

  end
end
