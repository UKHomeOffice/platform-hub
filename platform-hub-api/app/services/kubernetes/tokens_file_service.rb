require 'csv'

module Kubernetes
  module TokensFileService
    module Errors
      class UnknownStaticTokensKind < StandardError; end
    end

    STATIC_TOKEN_KINDS = [
      :system,
      :user,
      :robot
    ]

    extend self

    def generate(cluster)
      CSV.generate(headers: false) do |csv|
        STATIC_TOKEN_KINDS.each do |kind|
          static_tokens(cluster.to_s, kind).each do |t|
            i = HashWithIndifferentAccess.new(t)
            row = [i[:token], i[:user], i[:uid]]
            row << i[:groups].join(',') unless i[:groups].empty?
            csv << row
          end
        end

        Identity.kubernetes.all.each do |i|
          user = i.user.email
          HashWithIndifferentAccess.new(i.data)[:tokens].each do |t|
            next if t[:cluster].to_sym != cluster.to_sym
            csv << [t[:token], user, t[:uid], t[:groups].join(',')]
          end
        end
      end
    end

    private
    
    # Static system tokens contain the full list of all core system tokens in use.
    # For example tokens used by kublet, controller-manager, etc. 
    #
    # Static user tokens contain the list of all user tokens currently in use.
    #
    # Static agent tokens contain all non-user specific tokens in use. 
    # These can include bot / CI tokens etc.
    def static_tokens(cluster, kind)
      unless STATIC_TOKEN_KINDS.include?(kind)
        raise Errors::UnknownStaticTokensKind, "`#{kind}` kind not supported."
      end
      HashRecord.kubernetes.find_by!(id: "#{cluster}-static-#{kind}-tokens").data
    end

  end
end
