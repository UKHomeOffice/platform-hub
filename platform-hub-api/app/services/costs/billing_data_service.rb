module Costs
  class BillingDataService

    extend Memoist
    extend SimpleMemoizedMethods

    COLUMNS = {
      date: 0,
      account_id: 1,
      region: 2,
      resource_type: 3,
      resource_id: 4,
      tags: 5,
      cost: 6
    }.freeze

    TAG_KEYS = {
      cluster: 'CLUSTER',
      namespace: 'NAMESPACE',
      project: 'PROJECT'
    }.freeze

    def initialize billing_data, cluster_lookup, namespace_lookup, project_lookup
      @header = billing_data[0]
      CSVHelper.validate_columns(@header, COLUMNS)

      @data = billing_data[1..-1]

      process_tags

      @cluster_lookup = cluster_lookup
      @namespace_lookup = namespace_lookup
      @project_lookup = project_lookup
    end

    simple_memoized_methods(
      :clusters_and_namespaces,
      :projects,
      :dates,
      :items
    )

    private

    def process_tags
      @data.each do |line|
        tags_string = line[COLUMNS[:tags]] || ''
        line[COLUMNS[:tags]] = parse_tags_from_string(tags_string)
      end
    end

    def parse_tags_from_string string
      string.split('&').each_with_object({}) do |i, obj|
        k, v = i.split('=')
        obj[Addressable::URI.unencode(k)] = Addressable::URI.unencode(v)
      end
    end

    def build_clusters_and_namespaces
      cluster_and_namespace_pairs = get_unique_tag_values(TAG_KEYS[:cluster], TAG_KEYS[:namespace])
      Costs::DataHelpers.build_clusters_and_namespaces(
        cluster_and_namespace_pairs,
        @cluster_lookup,
        @namespace_lookup
      )
    end

    def build_projects
      project_tags = get_unique_tag_values TAG_KEYS[:project]

      results = HashInitializer[:hash]

      project_tags.each do |(value)|
        project = @project_lookup.by_shortname value
        if project
          results[:mapped][project.shortname] = {
            project_id: project.id,
            project_shortname: project.shortname
          }
        else
          results[:unmapped][value] = { project_shortname: value }
        end
      end

      # Also get the projects from the mapped namespaces
      clusters_and_namespaces[:mapped].each do |(_, cluster)|
        cluster[:namespaces][:mapped].each do |(_, namespace)|
          next if results[:mapped].has_key?(namespace[:project_shortname])
          results[:mapped][namespace[:project_shortname]] = {
            project_id: namespace[:project_id],
            project_shortname: namespace[:project_shortname]
          }
        end
      end

      results
    end

    # When multiple tag_names are provided, will only output those that have at
    # least one of the values.
    # E.g: if two tag names were provided, will return `['foo', 'bar']` as well
    # as ['foo', nil] and [nil, 'bar'] if entries exist with those combinations
    # of tag values. This means that [nil, nil] should never be returned.
    def get_unique_tag_values *tag_names
      @data.each_with_object(Set.new) do |line, acc|
        values = tag_names.map do |n|
          line[COLUMNS[:tags]][n]
        end
        acc.add(values) if values.any?
      end
    end

    def build_dates
      @data.map do |line|
        line[COLUMNS[:date]]
      end.uniq.sort
    end

    def build_items
      @data.map(&method(:parse_and_map_line))
    end

    def parse_and_map_line line
      date = line[COLUMNS[:date]]
      cost = BigDecimal(line[COLUMNS[:cost]])
      resource_type = line[COLUMNS[:resource_type]]
      resource_id = line[COLUMNS[:resource_id]]
      tags = line[COLUMNS[:tags]]

      mapped = map_tags_and_classify_type(tags)

      {
        date: date,
        cost: cost,
        resource_type: resource_type,
        resource_id: resource_id,
      }.merge(mapped)
    end

    def map_tags_and_classify_type tags
      # Possible types:
      #
      # - :mapped_cluster_only
      #   - "Resources that are part of a cluster will be tagged with a KUBERNETES_CLUSTER tag."
      # - :unmapped_cluster_only
      #   - "Resources that are part of a cluster will be tagged with a KUBERNETES_CLUSTER tag."
      # - :mapped_cluster_and_mapped_namespace
      #   - "Resources that are part of a cluster and also belong to a team will be tagged with both a KUBERNETES_CLUSTER and a NAMESPACE tag."
      # - :mapped_cluster_and_unmapped_namespace
      #   - "Resources that are part of a cluster and also belong to a team will be tagged with both a KUBERNETES_CLUSTER and a NAMESPACE tag."
      # - :unmapped_cluster_and_namespace
      #   - "Resources that are part of a cluster and also belong to a team will be tagged with both a KUBERNETES_CLUSTER and a NAMESPACE tag."
      # - :mapped_project_directly
      #   - "Resources that are not part of a cluster and belong to a team will be tagged a PROJECT_SERVICE tag, which may be ACP."
      #   - "Resources that are not part of a cluster and belong to a team, and which are used within namespaces, will be tagged with both a PROJECT_SERVICE and a NAMESPACE tag."
      # - :unmapped_project_directly
      #   - "Resources that are not part of a cluster and belong to a team will be tagged a PROJECT_SERVICE tag, which may be ACP."
      #   - "Resources that are not part of a cluster and belong to a team, and which are used within namespaces, will be tagged with both a PROJECT_SERVICE and a NAMESPACE tag."
      # - :unknown
      #   - Anything else

      cluster_tag = tags[TAG_KEYS[:cluster]]
      cluster = cluster_tag.present? ? @cluster_lookup.by_name_or_alias(cluster_tag) : nil

      namespace_tag = tags[TAG_KEYS[:namespace]]
      namespace = cluster ? clusters_and_namespaces[:mapped][cluster.name][:namespaces][:mapped][namespace_tag] : nil

      project_tag = tags[TAG_KEYS[:project]]
      project = project_tag.present? ? @project_lookup.by_shortname(project_tag) : nil

      type_mapper = lambda do
        return :mapped_project_directly if project_tag.present? && project.present?
        return :unmapped_project_directly if project_tag.present? && !project.present?

        return :mapped_cluster_and_mapped_namespace if cluster_tag.present? &&
          cluster.present? &&
          namespace_tag.present? &&
          namespace.present?
        return :mapped_cluster_and_unmapped_namespace if cluster_tag.present? &&
          cluster.present? &&
          namespace_tag.present? &&
          !namespace.present?
        return :unmapped_cluster_and_namespace if cluster_tag.present? &&
          !cluster.present? &&
          namespace_tag.present? &&
          !namespace.present?

        return :mapped_cluster_only if cluster_tag.present? && cluster.present?
        return :unmapped_cluster_only if cluster_tag.present? && !cluster.present?

        return :unknown
      end

      results = {
        type: type_mapper.call,
        cluster_tag: cluster_tag,
        cluster_name: cluster ? cluster.name : nil,
        namespace_tag: namespace_tag,
        project_tag: project_tag
      }

      if namespace
        results.merge(namespace)
      elsif project
        results.merge(projects[:mapped][project.shortname])
      else
        results
      end
    end

  end
end
