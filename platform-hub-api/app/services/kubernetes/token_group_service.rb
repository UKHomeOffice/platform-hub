module Kubernetes
  module TokenGroupService
    extend self

    # Kubernetes token groups are stored in HashRecord as:
    # data: [
    #   {
    #     "id" => "some:group:identifier",
    #     "privileged" => true,
    #     "description" => "Privilege description"
    #   }
    #   ...
    # ]

    def create_or_update(opts = {})
      configuration = groups_hash_record

      group_index = configuration.data.find_index {|g| g['id'] == opts[:id] }

      new_config = {
        id: opts[:id],
        privileged: opts[:privileged] || false,
        description: opts[:description]
      }

      configuration.with_lock do
        if group_index.blank?
          configuration.data << new_config
        else
          new_data = configuration.data.dup
          new_data[group_index] = new_config
          configuration.data = new_data
        end

        configuration.save!
        "Created/updated `#{opts[:id]}` kubernetes token group"
      end
    end

    def delete(group_id)
      configuration = groups_hash_record
      configuration.with_lock do
        configuration.data.reject! do |g|
          g['id'] == group_id.to_s
        end
        configuration.save!
        "Deleted `#{group_id}` kubernetes token group"
      end
    end

    def groups_hash_record
      HashRecord.kubernetes.find_or_create_by!(id: 'groups') do |r|
        r.data = []
      end
    end

    def list
      groups_hash_record.data
    end

    def get id
      list.find {|g| g['id'] == id} || {}
    end

    def privileged_groups
      list.select {|g| g['privileged'] == true}
    end

    def privileged_group_ids
      privileged_groups.map {|g| g['id']}
    end

  end
end
