module Costs
  class ReportResultsGeneratorService

    extend Memoist
    extend SimpleMemoizedMethods

    def initialize(billing_data_service, metrics_data_service, project_lookup, service_name_lookup)
      @billing_data_service = billing_data_service
      @metrics_data_service = metrics_data_service

      @project_lookup = project_lookup
      @service_name_lookup = service_name_lookup
    end

    simple_memoized_methods :prepare_results

    def report_results config
      build_report_results config
    end

    private

    def build_prepare_results
      {
        billing: {
          clusters_and_namespaces: @billing_data_service.clusters_and_namespaces,
          projects: @billing_data_service.projects,
        },
        metrics: {
          metric_types: @metrics_data_service.metric_types,
          clusters_and_namespaces: @metrics_data_service.clusters_and_namespaces,
        }
      }
    end

    def build_report_results config
      # Example config:
      # {
      #   "metric_weights": {
      #     "memory": 40,
      #     "cpu": 60
      #   },
      #   "shared_projects": ['BOO'],
      #   "cluster_groups_for_shared_services": ['Shared'],
      #   "cluster_groups": {
      #     "Prod": ['prod1', 'prod2'],
      #     "NotProd": ['notprod1', 'dev1', 'notprod2'],
      #     "Shared": ['ci', 'ops']
      #   }
      # }

      shared_projects = config[:shared_projects]

      cluster_groups_for_shared_services = config[:cluster_groups_for_shared_services]

      cluster_groups = config[:cluster_groups]
      cluster_name_to_group_map = cluster_groups.each_with_object({}) do |(group, names), obj|
        names.each do |n|
          obj[n] = group
        end
      end

      # Get the list of dates we need to care about

      dates = @billing_data_service.dates

      # Normalise the metric weights provided in the config

      metrics_weights_total = config[:metric_weights].values.map{ |v| BigDecimal(v) }.sum
      metric_weights = config[:metric_weights].each_with_object({}) do |(name, weight), obj|
        obj[name] = (BigDecimal(weight) / metrics_weights_total)
      end

      # Get the relevant metrics usage

      metrics_totals, metrics_grouped = @metrics_data_service.totals_and_grouped.values_at(
        :totals,
        :grouped
      )

      # Further group/accumulate the billing items into the categories needed.
      #
      # This also serves the purpose of validating/checking the data from the
      # billing data service to ensure we can process everything given.

      billing_accumulations = accumulate_billing_items(
        dates,
        @billing_data_service.items,
        shared_projects
      )

      # Now we iteratively build up the shared costs breakdown and project bills

      shared_costs_breakdown = SharedCostsBreakdownBuilderService.new(
        dates,
        @project_lookup,
        @service_name_lookup
      )

      project_bills = ProjectBillsBuilderService.new(
        @project_lookup,
        @service_name_lookup
      )

      billing_accumulations.each do |(date, h)|

        # Known resource costs

        # … for not shared projects
        process_known_resource_costs_for_projects(
          date,
          h[:projects],
          project_bills.method(:add_known_resource_cost_for_top_level),
          project_bills.method(:add_known_resource_cost_for_service)
        )

        # … for shared projects
        process_known_resource_costs_for_projects(
          date,
          h[:shared][:from_shared_projects],
          shared_costs_breakdown.method(:add_project_known_resource_cost_for_top_level),
          shared_costs_breakdown.method(:add_project_known_resource_cost_for_service)
        )

        # Unmapped
        shared_costs_breakdown.add_unmapped_cost(
          date,
          h[:shared][:from_unmapped][:total]
        )

        # Unknown
        shared_costs_breakdown.add_unknown_cost(
          date,
          h[:shared][:from_unknown][:total]
        )
      end

      # Share out the cluster-specific accumulations based on actual resource
      # usage - these are the Kubernetes cluster costs that we now need to
      # distribute across projects based on the resource usage of their
      # namespaces within that cluster.
      #
      # Note: this includes all shared project services too as we want to
      # account for their usage within clusters (across all cluster groups).

      # Also build up the non shared projects' cluster group totals so we can
      # use these later to work out proportions of bills within the cluster
      # group (i.e. excluding shared project costs within the cluster groups).
      non_shared_project_cluster_group_totals = HashInitializer[:hash, BigDecimal('0')]

      metrics_grouped.each do |(cluster_name, h1)|
        group_name = cluster_name_to_group_map[cluster_name]

        raise "Cluster '#{cluster_name}' has not been allocated to a cluster group" if group_name.blank?

        h1.each do |(date, h2)|
          next unless billing_accumulations[date][:clusters].has_key?(cluster_name)

          cluster_day_total_cost = billing_accumulations[date][:clusters][cluster_name][:total]

          h2.each do |(project_id, h3)|
            project_shortname = @project_lookup.by_id(project_id).shortname
            is_shared = shared_projects.include?(project_shortname)

            h3.each do |(service_id, metrics)|
              day_bill = metrics.reduce(BigDecimal('0')) do |amount, (metric_name, entries)|
                cluster_day_metric_total = metrics_totals[cluster_name][date][metric_name]

                proportion = entries.values.sum / cluster_day_metric_total
                proportion = 0 if proportion.nan? || proportion.infinite?

                amount + (proportion * cluster_day_total_cost * metric_weights[metric_name])
              end

              args = [
                project_id,
                service_id,
                date,
                group_name,
                cluster_name,
                day_bill
              ]

              if is_shared
                shared_costs_breakdown.set_project_usage_allocated_cost_for_service(*args)
              else
                project_bills.set_usage_allocated_cost_for_service(*args)

                non_shared_project_cluster_group_totals[date][group_name] += day_bill
              end
            end
          end
        end
      end

      # It's possible that we have no metrics for an entire day for an entire
      # cluster, in which case we have some costs not accounted for. We should
      # capture those daily costs in a separate shared pot.

      billing_accumulations.each do |(date, h1)|
        h1[:clusters].each do |(cluster_name, h2)|
          unless metrics_totals[cluster_name].has_key?(date)
            shared_costs_breakdown.add_missing_metrics_cost(cluster_name, date, h2[:total])
          end
        end
      end

      # Now allocate the shared project(s) cluster group costs to the non shared
      # projects based on the proportion, amongst other non shared projects
      # only, of their bills *within* that cluster group.
      #
      # Note: we skip cluster groups that host shared services, as these need be
      # shared across all projects, not just the ones running within those
      # cluster groups.

      shared_costs_breakdown.data.each do |(date, h1)|
        h1[:from_shared_projects].each do |(shared_project_id, h2)|
          next unless h2.has_key?(:services)

          h2[:services].each do |(shared_service_id, h3)|
            shared_cluster_group_totals = h3[:cluster_groups].each_with_object(HashInitializer[BigDecimal('0')]) do |(group_name, entries), acc|
              acc[group_name] += entries.values.sum
            end

            project_bills.data.each do |(project_id, h4)|
              entry = h4[:bills][date]

              next unless entry.has_key?(:services)

              entry[:services].each do |(service_id, h5)|
                h5[:cluster_groups].each do |(group_name, h6)|
                  next if cluster_groups_for_shared_services.include?(group_name)

                  proportion = h6.values.sum / non_shared_project_cluster_group_totals[date][group_name]
                  proportion = 0 if proportion.nan? || proportion.infinite?

                  allocated = proportion * shared_cluster_group_totals[group_name]

                  project_bills.add_allocated_cluster_group_cost_from_shared_project_for_service(
                    project_id,
                    service_id,
                    date,
                    shared_project_id,
                    shared_service_id,
                    group_name,
                    allocated
                  )
                end
              end
            end
          end
        end
      end

      # Now split out the rest of the shared pool based on the *overall*
      # proportion of bills from all cluster groups combined.
      #
      # Make sure to include the shared services costs from the cluster groups
      # that primarily host shared services.

      total_non_shared_project_cluster_groups_bills = HashInitializer[BigDecimal('0')]

      non_shared_project_cluster_group_totals.each do |(date, cluster_group)|
        total_non_shared_project_cluster_groups_bills[date] += cluster_group.values.sum
      end

      project_bills.data.each do |(project_id, h1)|
        h1[:bills].each do |(date, h2)|
          next unless h2.has_key?(:services)

          h2[:services].each do |(service_id, h3)|
            service_cluster_groups_total = h3[:cluster_groups].reduce(BigDecimal('0')) do |acc, (_, entries)|
              acc += entries.values.sum
            end

            proportion = service_cluster_groups_total / total_non_shared_project_cluster_groups_bills[date]
            proportion = 0 if proportion.nan? || proportion.infinite?

            # Missing metrics costs
            shared_costs_breakdown.data[date][:from_missing_metrics].each do |(cluster_name, cluster_total)|
              project_bills.add_shared_missing_metrics_allocated_cost_for_service(
                project_id,
                service_id,
                date,
                cluster_name,
                proportion * cluster_total
              )
            end

            # Unmapped costs
            unmapped_total = shared_costs_breakdown.data[date][:from_unmapped]
            project_bills.add_shared_unmapped_allocated_cost_for_service(
              project_id,
              service_id,
              date,
              proportion * unmapped_total
            )

            # Unknown costs
            unknown_total = shared_costs_breakdown.data[date][:from_unknown]
            project_bills.add_shared_unknown_allocated_cost_for_service(
              project_id,
              service_id,
              date,
              proportion * unknown_total
            )

            # Shared projects costs
            shared_costs_breakdown.data[date][:from_shared_projects].each do |(shared_project_id, h4)|

              # Top level known resources
              project_bills.add_allocated_known_resource_cost_from_shared_project_top_level_for_service(
                project_id,
                service_id,
                date,
                shared_project_id,
                proportion * h4[:top_level][:known_resources]
              )

              # Shared services within these shared projects
              next unless h4.has_key?(:services)
              h4[:services].each do |(shared_service_id, h5)|
                # Shared services known resources
                project_bills.add_allocated_known_resource_cost_from_shared_project_service_for_service(
                  project_id,
                  service_id,
                  date,
                  shared_project_id,
                  shared_service_id,
                  proportion * h5[:known_resources]
                )

                # Cluster groups that specifically host these shared services
                cluster_groups_for_shared_services.each do |group_name|
                  next unless h5[:cluster_groups].has_key?(group_name)

                  amount = h5[:cluster_groups][group_name].values.sum

                  project_bills.add_allocated_cluster_group_cost_from_shared_project_for_service(
                    project_id,
                    service_id,
                    date,
                    shared_project_id,
                    shared_service_id,
                    group_name,
                    proportion * amount
                  )
                end
              end

            end
          end
        end
      end

      # We need to *store* the BigDecimal values as Integer cents.
      bigdecimal_to_integer_cents = -> (v) { (v * 100).round.to_i }

      shared_costs_breakdown_data = HashUtils.deep_convert_values_of_type(
        shared_costs_breakdown.data_rolled_up,
        BigDecimal,
        &bigdecimal_to_integer_cents
      )

      project_bills_data = HashUtils.deep_convert_values_of_type(
        project_bills.data_rolled_up,
        BigDecimal,
        &bigdecimal_to_integer_cents
      )

      {
        shared_costs_breakdown: shared_costs_breakdown_data,
        project_bills: project_bills_data,
      }
    end

    def accumulate_billing_items(dates, billing_items, shared_projects)
      accumulations = HashUtils.initialize_hash_with_keys_with_defaults(dates) do
        {
          projects: HashInitializer[:hash],
          clusters: HashInitializer[:hash, :array],
          shared: {
            from_shared_projects: HashInitializer[:hash],
            from_unmapped: HashInitializer[:array],
            from_unknown: HashInitializer[:array]
          }
        }
      end

      billing_items.each do |item|
        date = item[:date]

        entry = setup_and_get_accumulation_entry(
          accumulations[date],
          item,
          shared_projects
        )

        entry[:items] << item

        cost = item[:cost]
        entry[:total] = BigDecimal('0') unless entry.has_key?(:total)
        entry[:total] += cost
      end

      accumulations
    end

    def setup_and_get_accumulation_entry(date_accumulation, item, shared_projects)
      case item[:type]

      when :unmapped_cluster_only,
           :mapped_cluster_and_unmapped_namespace,
           :unmapped_cluster_and_namespace,
           :unmapped_project_directly
        date_accumulation[:shared][:from_unmapped]

      when :unknown
        date_accumulation[:shared][:from_unknown]

      when :mapped_cluster_only
        cluster_name = item[:cluster_name]
        date_accumulation[:clusters][cluster_name]

      when :mapped_cluster_and_mapped_namespace,
           :mapped_project_directly
        project_id = item[:project_id]
        project_shortname = item[:project_shortname]

        category_group = if shared_projects.include?(project_shortname)
          date_accumulation[:shared][:from_shared_projects]
        else
          date_accumulation[:projects]
        end

        unless category_group.has_key?(project_id)
          category_group[project_id][:shortname] = project_shortname
        end

        project_entry = category_group[project_id]

        unless project_entry.has_key?(:top_level)
          project_entry[:top_level] = HashInitializer[:array]
          project_entry[:top_level][:total] = BigDecimal('0')
        end

        service_id = item[:service_id]
        service_name = item[:service_name]
        if service_id.present?
          unless project_entry.has_key?(:services)
            project_entry[:services] = HashInitializer[:hash, :array]
          end

          unless project_entry[:services].has_key?(service_id)
            project_entry[:services][service_id][:name] = service_name
            project_entry[:services][service_id][:total] = BigDecimal('0')
          end

          project_entry[:services][service_id]
        else
          project_entry[:top_level]
        end

      else
        raise "Unidentified billing data item group type detected in costs reports results generator. Type = #{type}."
      end
    end

    def process_known_resource_costs_for_projects(date, project_accumulations, top_level_adder, service_adder)
      project_accumulations.each do |(project_id, p_data)|
        top_level_total = p_data[:top_level][:total]
        top_level_adder.call(project_id, date, top_level_total)

        next unless p_data.has_key?(:services)

        p_data[:services].each do |(service_id, s_data)|
          service_total = s_data[:total]
          service_adder.call(project_id, service_id, date, service_total)
        end
      end
    end

  end
end
