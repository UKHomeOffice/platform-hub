module Kubernetes
  module TokenClaimService
    extend TokenLookup
    extend self

    module Errors
      class TokenNotFound < StandardError; end
      class TokenAlreadyDefinedForCluster < StandardError; end
      class TokenInvalid < StandardError; end
      class TokenAlreadyClaimed < StandardError; end
    end

    def claim_token(user, token)
      claim = lookup(token)

      if claim.nil?
        raise Errors::TokenNotFound, "Token `#{token}` not found!"
      end

      if claim.user.nil?
        begin
          ActiveRecord::Base.transaction do
            migrate_claimed_token_to_user_kubernetes_identity(user, claim)
            remove_claimed_token_from_static_list(claim)
          end
        rescue => e
          raise
        end
        [ claim.cluster, "Claimed `#{claim.cluster}` token." ]

      elsif claim.user.present?
        raise Errors::TokenAlreadyClaimed, "Token already claimed!"
      end
    end

    private

    def migrate_claimed_token_to_user_kubernetes_identity(user, claim)
      identity = 
        user.identity(:kubernetes) || 
        user.identities.create!(
          provider: :kubernetes,
          external_id: user.email,
          data: {tokens: []}
        )

      # Kubernetes identity token for given cluster exists:
      # groups assigned by admin take precedence over the ones from claimed token!
      existing_for_cluster = identity.data['tokens'].find {|t| t['cluster'] == claim.cluster}
      groups = if existing_for_cluster
        existing_for_cluster['groups']
      else
        claim.data.groups
      end

      tokens, created_token = Kubernetes::TokenService.create_or_update_token(
        identity.data,
        identity.id,
        claim.cluster,
        groups,
        claim.data.token
      )

      raise Errors::TokenInvalid, "User `#{user.email}` token invalid: #{created_token.errors.full_messages.join('; ')}" unless created_token.valid?

      identity.with_lock do
        identity.data['tokens'] = tokens
        identity.save!
      end
    end

    def remove_claimed_token_from_static_list(claim)
      static_user_tokens = HashRecord.kubernetes.find_by(id: "#{claim.cluster.to_s}-static-user-tokens")
      return nil if static_user_tokens.blank?

      static_user_tokens.with_lock do
        static_user_tokens.data.reject! do |t|
          ENCRYPTOR.decrypt(t['token']) == ENCRYPTOR.decrypt(claim.data.token)
        end
        static_user_tokens.save!
      end
    end

  end
end
