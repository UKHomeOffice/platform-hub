require 'csv'

module CostsReportGeneratorService

  module Errors
    class UnmappedClusters < StandardError
    end
  end

  extend self

  AWS_ACCOUNT_REGEX = /\A([\w\s]+) \(([0-9]{12})\).*\z/

  # Billing data is expected to be in the format exported through the AWS billing console, example (note the special first column + second row):
  #
  # ```csv
  # LinkedAccount,Foo Prod (658712345666)($),Foo Testing (670930123456)($),Foo Ops (123456634857)($),Foo Not Prod (449123456214)($),Foo VPN (123456902664)($),Foo CI (123456301818)($),Total cost ($)
  # LinkedAccount Total,5.854848,5608.76647753119962,7204.07218814469975,3037.63613003199993,38.688,1659.467127575999972,17554.48477128389853
  # 2017-10-31,0.222336,223.51990206119996,247.3549233528,97.93516799999999,1.248,53.613504,623.893833414
  # 2017-10-30,0.222336,223.54926147919997,247.3549233528,97.935168,1.248,53.613504,623.923192832
  # ...
  # ```

  # Metrics data example:
  #
  # ```csv
  # day,cluster,namespace,memory.used.percent,cpu.used.percent
  # 2017-10-01,658712345666,foo,74.583,11.924
  # 2017-10-01,658712345666,bar,153.656,21.426
  # 2017-10-01,123456634857,baz,43.176,5.264
  # 2017-10-01,658712345666,bob-prod,11.468,1.042
  # 2017-10-01,658712345666,bob-dev,63.668,8.774
  # 2017-10-01,658712345666,bob-super-secret-prod,44.289,1.86
  # 2017-10-01,658712345666,jane-prod,254.971,5.311
  # 2017-10-01,670930123456,smoke-test,25.03,2.051
  # ...
  # ```

  def prepare year:, month:, billing_csv_string:, metrics_csv_string:
    billing_data = parse_csv(billing_csv_string)
    metrics_data = parse_csv(metrics_csv_string)

    clusters_by_account_id_map = KubernetesCluster
      .all
      .each_with_object({}) do |c, obj|
        if c.aws_account_id
          obj[c.aws_account_id] = c
        end
      end

    results = {
      accounts: accounts(billing_data, clusters_by_account_id_map),
      namespaces: namespaces(metrics_data, clusters_by_account_id_map),
      metrics: metrics(metrics_data)
    }

    [
      results,
      billing_data,
      metrics_data
    ]
  end

  def build year:, month:, notes:, billing_csv_string:, metrics_csv_string:, config:
    prepare_results, billing_data, metrics_data = prepare(
      year: year,
      month: month,
      billing_csv_string: billing_csv_string,
      metrics_csv_string: metrics_csv_string
    )

    raise Error::UnmappedClusters if prepare_results[:accounts][:unmapped].any?

    mapped_accounts = prepare_results[:accounts][:mapped]
    mapped_namespaces = prepare_results[:namespaces][:mapped]
    metrics = prepare_results[:metrics]

    project_bills = generate_project_bills(
      accounts: mapped_accounts,
      namespaces: mapped_namespaces,
      metrics: metrics,
      billing_data: billing_data,
      metrics_data: metrics_data,
      config: config
    )

    ignored_namespaces = prepare_results[:namespaces][:unmapped].map do |n|
      n.slice :account_id, :cluster_name, :namespace_name
    end

    {
      accounts: mapped_accounts,
      project_bills: project_bills,
      ignored_namespaces: ignored_namespaces
    }
  end

  private

  def parse_csv csv_string
    CSV.parse csv_string
  end

  def accounts data, clusters_by_account_id_map
    results = {
      mapped: [],
      unmapped: []
    }

    # Note: in the CSV data...
    # - the 1st row is headers
    # - the 2nd row is a special totals row

    columns = data[0]
    totals = data[1]

    # First and last columns are special columns, rest are accounts
    start_ix = 1
    columns[start_ix..-2].each.with_index(start_ix) do |s, ix|
      matches = AWS_ACCOUNT_REGEX.match(s)
      if matches.present?
        account_id = matches[2].to_i
        cluster = clusters_by_account_id_map[account_id]

        entry = {
          account_name: matches[1],
          account_id: account_id,
          total_bill: totals[ix].to_f,
          cluster_name: cluster&.name,
          csv_column_index: ix
        }

        (cluster ? results[:mapped] : results[:unmapped]) << entry
      end
    end

    results
  end

  def namespaces data, clusters_by_account_id_map
    results = {
      mapped: [],
      unmapped: []
    }

    data[1..-1].map do |(_, account_id, namespace)|
      [account_id.to_i, namespace]
    end.uniq.each do |(account_id, namespace_name)|
      cluster = clusters_by_account_id_map[account_id]
      namespace = if cluster
        KubernetesNamespace
          .by_cluster(cluster)
          .by_name(namespace_name)
          .includes(service: :project)
          .first
      else
        nil
      end
      service = namespace&.service
      project = service&.project

      entry = {
        account_id: account_id,
        cluster_name: cluster&.name,
        namespace_id: namespace&.id,
        namespace_name: namespace_name,
        project_id: project&.id,
        project_shortname: project&.shortname,
        service_id: service&.id,
        service_name: service&.name
      }

      (namespace ? results[:mapped] : results[:unmapped]) << entry
    end

    results
  end

  def metrics data
    columns = data[0]
    # After the first 3 columns we have metric names
    start_ix = 3
    columns[start_ix..-1].map.with_index(start_ix) do |s, ix|
      {
        name: s,
        csv_column_index: ix
      }
    end
  end

  def generate_project_bills accounts:, namespaces:, metrics:, billing_data:, metrics_data:, config:
    # Example output structure:
    # {
    #   '<project_id>' => {
    #     'shortname' => 'foo',
    #     'name' => 'foooooooo',
    #     'cost_centre_code' => 'cost_centre_code',
    #     'totals' => {
    #       'clusters' => { 'acp-notprod' => 10200.02, 'acp-prod' => 10100.01 },
    #       'shared_services' => 10101.1
    #     },
    #     'services' => {
    #       '<service_id>' => {
    #         'name' => 'bar',
    #         'daily' => {
    #           '2017-10-01' => {
    #             'clusters' => { 'acp-notprod' => 200.02, 'acp-prod' => 100.01 },
    #             'shared_services' => 101.1
    #           },
    #           '2017-10-02' => {
    #             'clusters' => { 'acp-notprod' => 201.02, 'acp-prod' => 101.01 },
    #             'shared_services' => 102.1
    #           }
    #         },
    #         'totals' => {
    #           'clusters' => { 'acp-notprod' => 10200.02, 'acp-prod' => 10100.01 },
    #           'shared_services' => 10101.1
    #         }
    #       }
    #     }
    #   }
    # }

    shared_accounts_by_id = {}
    non_shared_accounts_by_id = {}
    accounts.each do |a, obj|
      account_id = a[:account_id]
      if config[:shared_costs][:clusters].include?(a[:cluster_name])
        shared_accounts_by_id[account_id] = a
      else
        non_shared_accounts_by_id[account_id] = a
      end
    end

    namespaces_by_account_and_name = namespaces.each_with_object(HashInitializer[:hash]) do |n, obj|
      obj[n[:account_id]][n[:namespace_name]] = n
    end

    bills_per_day_by_account = billing_data[2..-1].each_with_object(HashInitializer[:hash]) do |r, obj|
      day = r[0]

      # Only use the accounts specified, not accounts directly in the CSV (just in case)
      accounts.each do |a|
        obj[day][a[:account_id]] = r[a[:csv_column_index]].to_f
      end
    end

    # Build up the intermediate metrics totals and collections by project and service

    metrics_total_per_day_by_account_and_metric = HashInitializer[
      :hash,
        :hash,
          0.0
    ]
    metrics_lists_per_day_by_account_and_project_and_service_and_metric = HashInitializer[
      :hash,
        :hash,
          :hash,
            :hash,
              :array
    ]

    metrics_data[1..-1].each do |r|
      day = r[0]

      next unless bills_per_day_by_account.has_key?(day)

      account_id = r[1].to_i

      # Only count non shared accounts
      next unless non_shared_accounts_by_id.has_key?(account_id)

      # Only count namespaces that have been mapped
      namespace_name = r[2]
      namespace = namespaces_by_account_and_name[account_id][namespace_name]
      if namespace

        # Only use if project is not in the excluded_projects list
        next if config[:excluded_projects].include?(namespace[:project_id])

        # Add to day total and to project metrics list
        # Only use the metrics specified
        metrics.each do |m|
          metric_name = m[:name]
          metric_value = r[m[:csv_column_index]].to_f

          metrics_total_per_day_by_account_and_metric[day][account_id][metric_name] += metric_value

          project_id = namespace[:project_id]
          service_id = namespace[:service_id]
          metrics_lists_per_day_by_account_and_project_and_service_and_metric[day][account_id][project_id][service_id][metric_name] << metric_value
        end

      end
    end

    # Now build up the project bills per day

    metrics_weights_total = config[:metric_weights].values.map(&:to_f).sum
    metric_weights = config[:metric_weights].each_with_object({}) do |(name, weight), obj|
      obj[name] = (weight.to_f / metrics_weights_total)
    end

    bills_per_day_by_project_and_service_and_account = HashInitializer[
      :hash,
        :hash,
          :hash,
            0.0
    ]

    metrics_lists_per_day_by_account_and_project_and_service_and_metric.each do |day, h1|
      h1.each do |account_id, h2|
        account_day_bill = bills_per_day_by_account[day][account_id]
        h2.each do |project_id, h3|
          h3.each do |service_id, ms|
            service_day_bill = ms.reduce(0.0) do |amount, (metric_name, metric_values)|
              proportion = metric_values.sum / metrics_total_per_day_by_account_and_metric[day][account_id][metric_name]
              amount + (proportion * account_day_bill * metric_weights[metric_name])
            end

            bills_per_day_by_project_and_service_and_account[day][project_id][service_id][account_id] = service_day_bill
          end
        end
      end
    end

    # Now calculate the shared costs

    shared_allocation_weight = config[:shared_costs][:allocation_percentage].to_f / 100

    shared_bills_per_day_by_project_and_service = HashInitializer[
      :hash,
        :hash,
          0.0
    ]

    bills_per_day_by_project_and_service_and_account.each do |day, h1|
      shared_overall_day_total = 0.0
      non_shared_overall_day_total = 0.0
      bills_per_day_by_account[day].each do |account_id, amount|
        if shared_accounts_by_id.has_key?(account_id)
          shared_overall_day_total += amount
        else
          non_shared_overall_day_total += amount
        end
      end

      h1.each do |project_id, h2|
        h2.each do |service_id, account_bills|
          non_shared_project_service_day_total = account_bills.reduce(0.0) do |total, (_, amount)|
            total + amount
          end

          shared_day_bill = (non_shared_project_service_day_total / non_shared_overall_day_total) * shared_overall_day_total * shared_allocation_weight

          shared_bills_per_day_by_project_and_service[day][project_id][service_id] = shared_day_bill
        end
      end
    end

    # Now calculate the project and service totals

    totals_per_project_by_account = HashInitializer[:hash, 0.0]
    totals_per_project_by_service_and_account = HashInitializer[
      :hash,
        :hash,
          0.0
    ]

    shared_totals_per_project = HashInitializer[0.0]
    shared_totals_per_project_by_service = HashInitializer[:hash, 0.0]

    bills_per_day_by_project_and_service_and_account.each do |day, h1|
      h1.each do |project_id, h2|
        h2.each do |service_id, h3|
          h3.each do |account_id, amount|
            totals_per_project_by_account[project_id][account_id] += amount
            totals_per_project_by_service_and_account[project_id][service_id][account_id] += amount
          end
        end
      end
    end

    shared_bills_per_day_by_project_and_service.each do |day, h1|
      h1.each do |project_id, h2|
        h2.each do |service_id, amount|
          shared_totals_per_project[project_id] += amount
          shared_totals_per_project_by_service[project_id][service_id] += amount
        end
      end
    end

    # Now transform the data into the final results

    projects_by_id = Project.all.each_with_object({}) { |p, obj| obj[p.id] = p }
    service_names_by_id = Service.all.pluck(:id, :name).each_with_object({}) { |(id, name), obj| obj[id] = name }

    account_to_clusters_proc = -> ((account_id, amount), clusters) do
      cluster_name = non_shared_accounts_by_id[account_id][:cluster_name]
      clusters[cluster_name] = amount.round(2)
    end

    bills_per_day_by_project_and_service_and_account.each_with_object({}) do |(day, h1), obj|
      h1.each do |project_id, h2|

        project_hash = if obj.has_key?(project_id)
          obj[project_id]
        else
          project = projects_by_id[project_id]

          project_cluster_totals = totals_per_project_by_account[project_id].each_with_object({}, &account_to_clusters_proc)

          obj[project_id] = {
            'shortname' => project.shortname,
            'name' => project.name,
            'cost_centre_code' => project.cost_centre_code,
            'totals' => {
              'clusters' => project_cluster_totals,
              'shared_services' => shared_totals_per_project[project_id].round(2)
            },
            'services' => {}
          }
        end

        h2.each do |service_id, account_bills|

          service_hash = if project_hash['services'].has_key?(service_id)
            project_hash['services'][service_id]
          else
            service_cluster_totals = totals_per_project_by_service_and_account[project_id][service_id].each_with_object({}, &account_to_clusters_proc)

            project_hash['services'][service_id] = {
              'name' => service_names_by_id[service_id],
              'totals' => {
                'clusters' => service_cluster_totals,
                'shared_services' => shared_totals_per_project_by_service[project_id][service_id].round(2)
              },
              'daily' => {}
            }
          end

          day_cluster_bills = account_bills.each_with_object({}, &account_to_clusters_proc)

          service_hash['daily'][day] = {
            'clusters' => day_cluster_bills,
            'shared_services' => shared_bills_per_day_by_project_and_service[day][project_id][service_id].round(2)
          }

        end
      end
    end
  end

end
