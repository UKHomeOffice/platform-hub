module CostsAndResourcesAnalysisService

  extend self

  def source_data project, billing_csv_string, metrics_csv_string
    prepare_results, billing_data, metrics_data = CostsReportGeneratorService.prepare_and_return_data(
      billing_csv_string,
      metrics_csv_string
    )

    mapped_accounts = prepare_results[:accounts][:mapped]
    mapped_namespaces = prepare_results[:namespaces][:mapped]

    project_namespaces = mapped_namespaces.select { |n| n[:project_id] == project.id }

    calculate_daily_usage(
      mapped_accounts,
      project_namespaces,
      prepare_results[:metrics],
      billing_data,
      metrics_data
    )
  end

  private

  def calculate_daily_usage accounts, namespaces, metrics, billing_data, metrics_data
    # Example output structure:
    # {
    #   '<cluster_name>' => {
    #     'account_id' => 1234,
    #     'account_name' => 'foo',
    #     'cluster_bills' => {
    #       'daily' => {
    #         '2017-10-01' => 100.23
    #       },
    #       'total' => 1000.01
    #     },
    #     'namespaces' => {
    #       '<namespace_name>' => {
    #         'namespace_id' => '<uuid>',
    #         'service_id' => '<uuid>',
    #         'service_name' => 'service1',
    #         'daily' => {
    #           '2017-10-01' => {
    #             'metrics': {
    #               '<metric1>' => 0.1,
    #               '<metric2>' => 0.12
    #             }
    #           }
    #         },
    #         'averages' => {
    #           'metrics' => {
    #             '<metric1>' => 0.15,
    #             '<metric2>' => 0.22
    #           }
    #         }
    #       }
    #     }
    #   }
    # }

    # Accounts and their bills

    accounts_by_id = accounts.each_with_object({}) do |a, obj|
      obj[a[:account_id]] = a
    end

    bills_per_account_by_day = billing_data[2..-1].each_with_object(HashInitializer[:hash]) do |r, obj|
      day = r[0]

      # Only use the accounts specified, not accounts directly in the CSV (just in case)
      accounts.each do |a|
        obj[a[:account_id]][day] = r[a[:csv_column_index]].to_f
      end
    end

    # Namespaces and their usages

    namespaces_by_account_and_name = namespaces.each_with_object(HashInitializer[:hash]) do |n, obj|
      obj[n[:account_id]][n[:namespace_name]] = n
    end

    metrics_total_per_day_by_account_and_metric = HashInitializer[
      :hash,
        :hash,
          0.0
    ]
    metrics_lists_per_day_by_account_and_namespace_and_metric = HashInitializer[
      :hash,
        :hash,
          :hash,
            :array
    ]

    metrics_data[1..-1].each do |r|
      day = r[0]
      account_id = r[1].to_i
      namespace_name = r[2]

      metrics.each do |m|
        metric_name = m[:name]
        metric_value = r[m[:csv_column_index]].to_f

        # Count ALL metrics for the _totals_ as we want to work out proportions of
        # usage against the whole dataset.
        #
        # BUT only store the _individual_ metrics for namespaces we care about.

        metrics_total_per_day_by_account_and_metric[day][account_id][metric_name] += metric_value

        if namespaces_by_account_and_name[account_id].key?(namespace_name)
          metrics_lists_per_day_by_account_and_namespace_and_metric[day][account_id][namespace_name][metric_name] << metric_value
        end
      end
    end

    metrics_proportion_per_account_by_namespace_by_day_and_metric = HashInitializer[
      :hash,
        :hash,
          :hash,
            0.0
    ]

    metrics_lists_per_day_by_account_and_namespace_and_metric.each do |(day, h1)|
      h1.each do |(account_id, h2)|
        h2.each do |(namespace_name, h3)|
          h3.each do |(metric_name, metric_values)|
            proportion = metric_values.sum / metrics_total_per_day_by_account_and_metric[day][account_id][metric_name]

            metrics_proportion_per_account_by_namespace_by_day_and_metric[account_id][namespace_name][day][metric_name] = proportion
          end
        end
      end
    end

    # Now transform the data into the final results

    namespaces_by_account_and_name.each_with_object({}) do |(account_id, h1), obj1|

      cluster_bills = {
        'daily' => bills_per_account_by_day[account_id],
        'total' => bills_per_account_by_day[account_id].values.sum
      }

      namespaces = h1.each_with_object({}) do |(namespace_name, h2), obj2|

        namespace_daily_metrics_proportions = HashInitializer[:hash, :hash, 0.0]
        namespace_metrics_proportions_lists = HashInitializer[:array]
        namespace_average_metrics_proportions = HashInitializer[:hash, 0.0]

        metrics_proportion_per_account_by_namespace_by_day_and_metric[account_id][namespace_name].each do |(day, metrics_hash)|
          namespace_daily_metrics_proportions[day]['metrics'] = metrics_hash

          metrics_hash.each do |(metric_name, metric_proportion)|
            namespace_metrics_proportions_lists[metric_name] << metric_proportion
          end
        end

        namespace_metrics_proportions_lists.each do |(metric_name, values)|
          average = values.reduce(:+) / values.size
          namespace_average_metrics_proportions['metrics'][metric_name] = average
        end

        namespace_data = {
          'namespace_id' => h2[:namespace_id],
          'service_id' => h2[:service_id],
          'service_name' => h2[:service_name],
          'daily' => namespace_daily_metrics_proportions,
          'averages' => namespace_average_metrics_proportions
        }

        obj2[namespace_name] = namespace_data

      end

      cluster_data = {
        'account_id' => account_id,
        'account_name' => accounts_by_id[account_id][:account_name],
        'cluster_bills' => cluster_bills,
        'namespaces' => namespaces
      }

      obj1[accounts_by_id[account_id][:cluster_name]] = cluster_data

    end
  end

end
