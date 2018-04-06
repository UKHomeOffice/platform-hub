module Kubernetes
  class NamespaceLookupCacheService

    # IMPORTANT: this is intended to be a short lived cache – it does not update
    # stale items when namespaces have been updated, so it is recommended to
    # only use this in a single request/response cycle and only when doing lots
    # of namespace lookups.

    def initialize
      @cache = {}
    end

    def by_cluster_and_name cluster, name
      raise "`cluster` must be a KubernetesCluster instance - got a #{cluster.class.name} instance" unless cluster.is_a?(KubernetesCluster)

      # We make the assumption here that a namespace can only exist once for a
      # particular cluster
      # (i.e. you can't have two namespaces 'foo' on cluster_1)
      downcased_name = name.downcase
      key = "#{cluster.name}/#{name}"

      find_and_populate_cache(cluster, downcased_name, key) unless @cache.has_key?(key)

      @cache[key]
    end

    private

    def find_and_populate_cache cluster, name, key
      namespace = KubernetesNamespace
        .by_cluster(cluster)
        .by_name(name)
        .includes(service: :project)
        .first

      @cache[key] = namespace if namespace
    end

  end
end
