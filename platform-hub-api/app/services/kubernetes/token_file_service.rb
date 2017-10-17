require 'csv'

module Kubernetes
  module TokenFileService

    BATCH_SIZE = 100

    extend self

    def generate(cluster_name)
      cluster = KubernetesCluster.find_by! name: cluster_name

      CSV.generate(headers: false) do |csv|
        KubernetesToken.by_cluster(cluster).find_each(batch_size: BATCH_SIZE) do |t|
          row = [t.decrypted_token, t.name, t.uid]
          row << t.groups.join(',') unless t.groups.blank?
          csv << row
        end
      end
    end

  end
end
