module Costs
  class ProjectBillsBuilderService

    # Bills structure:
    # {
    #   '<project_id>' => {
    #     shortname: 'FOO',
    #     name: 'foooooooo',
    #     cost_centre_code: '1234',
    #     bills: {
    #       '<date>' => {
    #         top_level: {
    #           known_resources: 0.0,
    #         },
    #         services: {
    #           '<service_id>' => {
    #             name: 'API service',
    #             known_resources: 0.0,
    #             cluster_groups: {
    #               '<cluster_group_name>' => {
    #                 '<cluster_name>' => 0.0
    #               }
    #             },
    #             shared: {
    #               from_shared_projects: {
    #                 '<project_id>': {
    #                   shortname: 'BAR',
    #                   top_level: {
    #                     known_resources: 0.0,
    #                   },
    #                   services: {
    #                     '<service_id>' => {
    #                       name: 'Core service',
    #                       known_resources: 0.0,
    #                       cluster_groups: {
    #                         '<cluster_group_name>': 0.0
    #                       }
    #                     }
    #                   }
    #                 }
    #               },
    #               from_shared_clusters: {
    #                 '<cluster_name>' => 0.0
    #               },
    #               from_missing_metrics: {
    #                 '<cluster_name>' => 0.0
    #               },
    #               from_unmapped: 0.0,
    #               from_unknown: 0.0
    #             }
    #           }
    #         }
    #       }
    #     }
    #   }
    # }

    attr_accessor :data

    def initialize project_lookup, service_name_lookup
      @data = HashInitializer[
        :hash,
          :hash,
            :hash,
              :hash,
                0.0
      ]

      @project_lookup = project_lookup
      @service_name_lookup = service_name_lookup
    end

    def add_known_resource_cost_for_top_level(project_id, date, amount)
      entry = get_project_entry(project_id, date)
      entry[:top_level][:known_resources] += amount
    end

    def add_known_resource_cost_for_service(project_id, service_id, date, amount)
      entry = get_service_entry(project_id, service_id, date)
      entry[:known_resources] += amount
    end

    def set_usage_allocated_cost_for_service(project_id, service_id, date, cluster_group_name, cluster_name, amount)
      entry = get_service_entry(project_id, service_id, date)
      entry[:cluster_groups][cluster_group_name][cluster_name] = amount
    end

    def add_allocated_cluster_group_cost_from_shared_project_for_service(project_id, service_id, date, shared_project_id, shared_service_id, cluster_group_name, amount)
      entry = get_service_shared_project_service_entry(project_id, service_id, date, shared_project_id, shared_service_id)
      entry[:cluster_groups][cluster_group_name] += amount
    end

    def add_allocated_known_resource_cost_from_shared_project_top_level_for_service(project_id, service_id, date, shared_project_id, amount)
      entry = get_service_shared_project_entry(project_id, service_id, date, shared_project_id)
      entry[:top_level][:known_resources] += amount
    end

    def add_allocated_known_resource_cost_from_shared_project_service_for_service(project_id, service_id, date, shared_project_id, shared_service_id, amount)
      entry = get_service_shared_project_service_entry(project_id, service_id, date, shared_project_id, shared_service_id)
      entry[:known_resources] += amount
    end

    def add_shared_cluster_allocated_cost_for_service(project_id, service_id, date, cluster_name, amount)
      entry = get_service_entry(project_id, service_id, date)[:shared][:from_shared_clusters]
      entry[cluster_name] += amount
    end

    def add_shared_missing_metrics_allocated_cost_for_service(project_id, service_id, date, cluster_name, amount)
      entry = get_service_entry(project_id, service_id, date)[:shared][:from_missing_metrics]
      entry[cluster_name] += amount
    end

    def add_shared_unmapped_allocated_cost_for_service(project_id, service_id, date, amount)
      entry = get_service_entry(project_id, service_id, date)[:shared]
      entry[:from_unmapped] += amount
    end

    def add_shared_unknown_allocated_cost_for_service(project_id, service_id, date, amount)
      entry = get_service_entry(project_id, service_id, date)[:shared]
      entry[:from_unknown] += amount
    end

    def data_rolled_up
      @data.each_with_object({}) do |(project_id, project_hash), results|
        daily_bills = project_hash[:bills]
        rolled_up_bills = daily_bills.reduce({}) do |acc, (_, h)|
          HashRollup.rollup(h, acc)
        end
        results[project_id] = project_hash.dup.merge({ bills: rolled_up_bills })
      end
    end

    private

    def get_project_entry(project_id, date)
      entry = @data[project_id]

      unless entry.has_key?(:shortname)
        project = @project_lookup.by_id project_id
        entry[:shortname] = project.shortname
        entry[:name] = project.name
        entry[:cost_centre_code] = project.cost_centre_code
      end

      entry[:bills][date]
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

    def get_service_shared_project_entry(project_id, service_id, date, shared_project_id)
      entry = get_service_entry(project_id, service_id, date)[:shared][:from_shared_projects][shared_project_id]

      unless entry.has_key?(:shortname)
        entry[:shortname] = @project_lookup.by_id(shared_project_id).shortname
      end

      entry
    end

    def get_service_shared_project_service_entry(project_id, service_id, date, shared_project_id, shared_service_id)
      entry = get_service_shared_project_entry(project_id, service_id, date, shared_project_id)

      unless entry[:services].has_key?(shared_service_id)
        entry[:services][shared_service_id] = {
          name: @service_name_lookup.by_id(shared_service_id)
        }.merge(initialize_empty_shared_project_service_entry)
      end

      entry[:services][shared_service_id]
    end

    def initialize_empty_service_entry
      {
        known_resources: 0.0,
        cluster_groups: HashInitializer[:hash, 0.0],
        shared: {
          from_shared_projects: HashInitializer[:hash, :hash, 0.0],
          from_shared_clusters: HashInitializer[0.0],
          from_missing_metrics: HashInitializer[0.0],
          from_unmapped: 0.0,
          from_unknown: 0.0
        }
      }
    end

    def initialize_empty_shared_project_service_entry
      {
        known_resources: 0.0,
        cluster_groups: HashInitializer[0.0],
      }
    end

  end
end
