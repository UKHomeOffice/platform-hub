module Kubernetes
  module TokenLookup

    IDENTITY_BATCH_SIZE = 100

    def lookup(token, kind = 'user')
      res = lookup_static_tokens(token, kind)
      res.empty? ? lookup_identities(token) : res
    end

    def lookup_static_tokens(token, kind = 'user')
      clusters = Kubernetes::ClusterService.list

      found = []

      clusters.each do |cluster|
        static_user_tokens = HashRecord.kubernetes.find_by(id: "#{cluster['id'].to_s}-static-#{kind.to_s}-tokens")
        next if static_user_tokens.blank?

        existing_token = static_user_tokens.data.find {|t| ENCRYPTOR.decrypt(t['token']) == token }
        if existing_token
          found << Hashie::Mash.new(
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

      found
    end

    def lookup_identities(token)
      found = []

      Identity.kubernetes.find_each(batch_size: IDENTITY_BATCH_SIZE) do |i|
        identity_tokens = i.data['tokens']
        next if identity_tokens.blank?

        existing_tokens = identity_tokens.select {|t| ENCRYPTOR.decrypt(t['token']) == token }

        existing_tokens.map do |existing_token|
          found << Hashie::Mash.new(
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

      found
    end

  end
end
