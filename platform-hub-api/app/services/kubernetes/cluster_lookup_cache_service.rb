module Kubernetes
  class ClusterLookupCacheService

    # IMPORTANT: this is intended to be a short lived cache – it does not update
    # stale items when clusters have been updated, so it is recommended to only
    # use this in a single request/response cycle and only when doing lots of
    # cluster lookups.

    def initialize
      @cache = {}
    end

    # This is a case insensitive lookup
    def by_name_or_alias value
      downcased_value = value.downcase
      find_and_populate_cache(downcased_value) unless @cache.has_key?(downcased_value)
      @cache[downcased_value]
    end

    private

    def find_and_populate_cache value
      cluster = KubernetesCluster.by_name_or_alias(value).first
      if cluster
        @cache[cluster.name.downcase] = cluster
        Array(cluster.aliases).each do |a|
          @cache[a.downcase] = cluster
        end
      end
    end

  end
end
