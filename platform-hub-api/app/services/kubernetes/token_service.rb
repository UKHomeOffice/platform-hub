module Kubernetes
  module TokenService
    extend self

    def tokens_from_identity_data(data)
      data.with_indifferent_access[:tokens].collect do |t|
        KubernetesToken.new(
          t.extract!(:identity_id, :cluster, :token, :uid, :groups)
        )
      end
    end

    def create_or_update_token(data, identity_id, cluster, groups)
      tokens = tokens_from_identity_data(data)
      existing_token = tokens.find {|t| t.cluster == cluster}
      
      if existing_token
        existing_token.groups = cleanup(groups)
        [tokens, existing_token]
      else
        new_token = KubernetesToken.new(
          identity_id: identity_id,
          cluster: cluster,
          groups: cleanup(groups),
          token: generate_secure_random,
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

    private

    def cleanup(groups)
      if groups.is_a? String
        groups.split(',').map(&:strip).reject(&:blank?).uniq
      else
        groups
      end
    end

  end
end
