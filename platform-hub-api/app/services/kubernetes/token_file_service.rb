require 'csv'

module Kubernetes
  module TokenFileService
    module Errors
      class UnknownStaticTokensKind < StandardError; end
    end

    # Static `system` tokens contain the full list of all core system tokens in use.
    # For example tokens used by kublet, controller-manager, etc. 
    #
    # Static `user` tokens contain the list of all user tokens currently in use.
    #
    # Static `robot` tokens contain all non-user specific tokens in use. 
    # These can include various robots, CI tokens etc.

    STATIC_TOKEN_KINDS = [
      :system,
      :user,
      :robot
    ]

    IDENTITY_BATCH_SIZE = 100

    extend self

    def generate(cluster)
      CSV.generate(headers: false) do |csv|
        STATIC_TOKEN_KINDS.each do |kind|
          static_tokens(cluster.to_s, kind).each do |t|
            i = HashWithIndifferentAccess.new(t)
            row = [ENCRYPTOR.decrypt(i[:token]), i[:user], i[:uid]]
            row << i[:groups].join(',') unless i[:groups].empty?
            csv << row
          end
        end

        Identity.kubernetes.find_each(batch_size: IDENTITY_BATCH_SIZE) do |i|
          user = i.user.email
          HashWithIndifferentAccess.new(i.data)[:tokens].each do |t|
            next if t[:cluster].to_sym != cluster.to_sym
            row = [ENCRYPTOR.decrypt(t[:token]), user, t[:uid]]
            row << t[:groups].join(',') unless t[:groups].blank?
            csv << row
          end
        end
      end
    end

    private
    
    def static_tokens(cluster, kind)
      unless STATIC_TOKEN_KINDS.include?(kind)
        raise Errors::UnknownStaticTokensKind, "`#{kind}` kind not supported."
      end
      hr = HashRecord.kubernetes.find_by(id: "#{cluster}-static-#{kind}-tokens")
      hr.try(:data) || []
    end

  end
end
