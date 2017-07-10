module Kubernetes
  module TokenRevokeService
    extend TokenLookup
    extend self

    module Errors
      class TokenNotFound < StandardError; end
    end

    def remove(token)
      tokens = lookup_identities(token) 
      tokens = tokens.empty? ? lookup_static_tokens(token, 'user') : tokens
      tokens = tokens.empty? ? lookup_static_tokens(token, 'robot') : tokens

      if tokens.empty?
        raise Errors::TokenNotFound, "Token `#{token}` not found!"
      end

      summary = []

      tokens.each do |t|
        if t.user.nil? # for static user/robot token
          begin
            Kubernetes::StaticTokenService.delete_by_token(t.cluster, t.kind, token)
          rescue
            raise
          end
          summary << [ t.cluster, "Revoked `#{t.cluster}` token in #{t.kind} static tokens" ]

        elsif t.user.present? # for token associated with user kubernetes identity
          identity = t.user.identity(:kubernetes)
          begin
            tokens, removed_token = Kubernetes::TokenService.delete_token(identity.data, t.cluster)

            if ENCRYPTOR.decrypt(removed_token['token']) == token
              identity.with_lock do
                identity.data['tokens'] = tokens
                identity.save!
              end
            end
          rescue
            raise
          end
          summary << [ t.cluster, "Revoked `#{t.cluster}` token in `#{t.user.email}` kubernetes identity" ]
        end
      end

      summary
    end

  end
end
