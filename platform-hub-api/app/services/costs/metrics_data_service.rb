module Costs
  class MetricsDataService

    extend Memoist
    extend SimpleMemoizedMethods

    COLUMNS = {
      date: 0,
      account_id: 1,
      cluster: 2,
      region: 3,
      namespace: 4
    }.freeze

    # Example `metrics_data`:
    #
    # [
    #   [ 'date', 'account_id', 'cluster', 'region', 'namespace', 'memory', 'cpu' ],
    #   [ '2018-02-01', '123456', 'prod', 'eu-west-1', 'ksm', '1.25600', '0.66000' ],
    #   [ '2018-02-01', '123456', 'prod', 'eu-west-1', 'virus-scan', '177.48000', '1.81500' ],
    #   [ '2018-02-01', '123456', 'prod', 'eu-west-1', '', '776.34600', '561.50200' ],
    #   [ '2018-02-01', '345678', 'dev', 'eu-west-2', 'kube-tls', '0.67200', '0.18900' ],
    #   [ '2018-02-01', '567888', 'dev.uk', 'eu-west-2', 'kube-cluster-autoscaler', '15.63300', '5.14600' ],
    #   [ '2018-02-01', '890788', 'preprod', 'eu-west-1', 'jira', '234.24700', '12.07100' ],
    #   [ '2018-02-01', '890788', 'preprod', 'eu-west-2', 'smoke-test', '7.63500', '54.29200' ],
    # ]
    def initialize metrics_data, cluster_lookup, namespace_lookup
      @header = metrics_data[0]
      CSVHelper.validate_columns(@header, COLUMNS)

      @data = metrics_data[1..-1]

      @cluster_lookup = cluster_lookup
      @namespace_lookup = namespace_lookup
    end

    simple_memoized_methods(
      :metric_types,
      :clusters_and_namespaces,
      :totals_and_grouped
    )

    private

    def build_metric_types
      start = COLUMNS.length  # After the known columns we have metric columns
      @header[start..-1].map.with_index(start) do |n, ix|
        {
          name: n,
          index: ix
        }
      end
    end

    def build_clusters_and_namespaces
      cluster_and_namespace_pairs = @data.each_with_object(Set.new) do |line, acc|
        values = [
          line[COLUMNS[:cluster]],
          line[COLUMNS[:namespace]]
        ]
        acc.add(values) if values.any?
      end

      Costs::DataHelpers.build_clusters_and_namespaces(
        cluster_and_namespace_pairs,
        @cluster_lookup,
        @namespace_lookup
      )
    end

    def build_totals_and_grouped
      # Example output structure:
      # {
      #   :totals => {
      #     '<cluster_name>' => {
      #       '<date>' => {
      #         '<metric_name>' => 5.5
      #       }
      #     }
      #   },
      #   :grouped => {
      #     '<cluster_name>' => {
      #       '<date>' => {
      #         '<project_id>' => {
      #           '<service_id>' => {
      #             'metrics' => {
      #               '<metric_name>': {
      #                 '<namespace_name>' => 1.2
      #               }
      #             }
      #           }
      #         }
      #       }
      #     }
      #   }
      # }
      # ---

      metrics_total_per_cluster_by_date_and_metric = HashInitializer[
        :hash,
          :hash,
            BigDecimal('0')
      ]
      metrics_per_cluster_by_date_and_project_and_service_and_metric_and_namespace = HashInitializer[
        :hash,
          :hash,
            :hash,
              :hash,
                :hash
      ]

      @data.each do |line|
        mapped = parse_and_map_line line

        date, cluster_name, project_id, service_id, namespace_name = mapped.values_at(
          :date,
          :cluster_name,
          :project_id,
          :service_id,
          :namespace_name
        )

        # If we don't know the cluster then we have no use for this line!
        next if cluster_name.blank?

        # Add to totals and project service grouped lists
        metric_types.each do |mt|
          metric_name = mt[:name]
          metric_value = BigDecimal(line[mt[:index]])

          if project_id && service_id && namespace_name
            entry = metrics_per_cluster_by_date_and_project_and_service_and_metric_and_namespace[cluster_name][date][project_id][service_id][metric_name]

            # Ignore if we've already seen a metric for that day
            next if entry[namespace_name].present?

            entry[namespace_name] = metric_value

            # Add to running totals
            metrics_total_per_cluster_by_date_and_metric[cluster_name][date][metric_name] += metric_value
          end
        end
      end

      {
        totals: metrics_total_per_cluster_by_date_and_metric,
        grouped: metrics_per_cluster_by_date_and_project_and_service_and_metric_and_namespace
      }
    end

    def parse_and_map_line line
      date = line[COLUMNS[:date]]

      cluster_name = line[COLUMNS[:cluster]]
      cluster = cluster_name.present? ? @cluster_lookup.by_name_or_alias(cluster_name) : nil

      namespace_name = line[COLUMNS[:namespace]]
      namespace = cluster ? clusters_and_namespaces[:mapped][cluster.name][:namespaces][:mapped][namespace_name] : nil

      {
        date: date,
        cluster_name: cluster ? cluster.name : nil
      }.merge(namespace || {})
    end

  end
end
