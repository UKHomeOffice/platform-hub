module Costs
  class SharedCostsBreakdownBuilderService

    attr_accessor :data

    def initialize dates, project_lookup, service_name_lookup
      @data = HashUtils.initialize_hash_with_keys_with_defaults(dates) do
        {
          from_shared_projects: HashInitializer[:hash, :hash, BigDecimal('0')],
          from_missing_metrics: HashInitializer[BigDecimal('0')],
          from_unmapped: BigDecimal('0'),
          from_unknown: BigDecimal('0')
        }
      end

      @project_lookup = project_lookup
      @service_name_lookup = service_name_lookup
    end

    def add_project_known_resource_cost_for_top_level(project_id, date, amount)
      entry = get_project_entry(project_id, date)
      entry[:top_level][:known_resources] += amount
    end

    def add_project_known_resource_cost_for_service(project_id, service_id, date, amount)
      entry = get_service_entry(project_id, service_id, date)
      entry[:known_resources] += amount
    end

    def add_missing_metrics_cost(cluster_name, date, amount)
      @data[date][:from_missing_metrics][cluster_name] += amount
    end

    def add_unmapped_cost(date, amount)
      @data[date][:from_unmapped] += amount
    end

    def add_unknown_cost(date, amount)
      @data[date][:from_unknown] += amount
    end

    def set_project_usage_allocated_cost_for_service(project_id, service_id, date, cluster_group_name, cluster_name, amount)
      entry = get_service_entry(project_id, service_id, date)
      entry[:cluster_groups][cluster_group_name][cluster_name] = amount
    end

    def data_rolled_up
      @data.reduce({}) do |acc, (_, h)|
        HashRollup.rollup(h, acc)
      end
    end

    private

    def get_project_entry(project_id, date)
      entry = @data[date][:from_shared_projects][project_id]

      if entry[:shortname].blank?
        project = @project_lookup.by_id project_id
        entry[:shortname] = project.shortname
        entry[:name] = project.name
      end

      entry
    end

    def get_service_entry(project_id, service_id, date)
      entry = get_project_entry(project_id, date)

      unless entry[:services].has_key?(service_id)
        entry[:services][service_id] = {
          name: @service_name_lookup.by_id(service_id)
        }.merge(initialize_empty_service_entry)
      end

      entry[:services][service_id]
    end

    def initialize_empty_service_entry
      {
        known_resources: BigDecimal('0'),
        cluster_groups: HashInitializer[:hash, BigDecimal('0')]
      }
    end

  end
end
