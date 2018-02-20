module Costs
  module DataHelpers

    extend self

    def build_clusters_and_namespaces unique_cluster_and_namespace_pairs, cluster_lookup, namespace_lookup
      results = HashInitializer[:hash]

      unique_cluster_and_namespace_pairs.each do |(cluster_value, namespace_value)|
        next if cluster_value.blank?

        cluster = cluster_lookup.by_name_or_alias cluster_value

        entry = if cluster
          if results[:mapped].has_key?(cluster.name)
            results[:mapped][cluster.name]
          else
            results[:mapped][cluster.name] = {
              cluster_name: cluster.name,
              costs_bucket: cluster.costs_bucket,
              namespaces: { mapped: {}, unmapped: {} }
            }
          end
        else
          if results[:unmapped].has_key?(cluster_value)
            results[:unmapped][cluster_value]
          else
            results[:unmapped][cluster_value] = {
              cluster_name: cluster_value,
              namespaces: { unmapped: {} }
            }
          end
        end

        if namespace_value
          namespace = if cluster
            namespace_lookup.by_cluster_and_name(cluster, namespace_value)
          end

          if namespace
            entry[:namespaces][:mapped][namespace.name] = Costs::DataHelpers.build_namespace_hash(namespace)
          else
            entry[:namespaces][:unmapped][namespace_value] = {
              namespace_name: namespace_value
            }
          end
        end
      end

      return results;
    end

    def build_namespace_hash namespace
      service = namespace.service
      project = service.project
      {
        namespace_id: namespace.id,
        namespace_name: namespace.name,
        project_id: project.id,
        project_shortname: project.shortname,
        service_id: service.id,
        service_name: service.name
      }
    end

  end
end
