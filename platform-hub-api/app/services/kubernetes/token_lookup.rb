module Kubernetes
  module TokenLookup

    IDENTITY_BATCH_SIZE = 100

    def lookup(token, kind = 'user')
      lookup_static_tokens(token, kind) || lookup_identities(token)
    end

    def lookup_static_tokens(token, kind = 'user')
      clusters = HashRecord.kubernetes.find_by(id: 'clusters')
      return nil if clusters.blank?

      clusters.data.each do |cluster|
        static_user_tokens = HashRecord.kubernetes.find_by(id: "#{cluster['id'].to_s}-static-#{kind.to_s}-tokens")
        next if static_user_tokens.blank?

        existing_token = static_user_tokens.data.find {|t| ENCRYPTOR.decrypt(t['token']) == token }
        if existing_token
          return Hashie::Mash.new(
            cluster: cluster['id'],
            data: {
              token: existing_token['token'],
              uid: existing_token['uid'],
              groups: existing_token['groups'],
            },
            kind: kind,
            user: nil
          )
        end
      end
      nil
    end

    def lookup_identities(token)
      Identity.kubernetes.find_each(batch_size: IDENTITY_BATCH_SIZE) do |i|
        identity_tokens = i.data['tokens']
        next if identity_tokens.blank?

        existing_token = identity_tokens.find {|t| ENCRYPTOR.decrypt(t['token']) == token }

        if existing_token
          return Hashie::Mash.new(
            cluster: existing_token['cluster'],
            data: {
              token: existing_token['token'],
              uid: existing_token['uid'],
              groups: existing_token['groups'],
            },
            user: i.user
          )
        end
      end
      nil
    end
    
  end
end
