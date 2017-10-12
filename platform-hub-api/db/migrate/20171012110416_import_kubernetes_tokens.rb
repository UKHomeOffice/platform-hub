class ImportKubernetesTokens < ActiveRecord::Migration[5.0]

  BATCH_SIZE = 100

  def up
    # Disable kubernetes token feature flag
    FeatureFlagService.create_or_update(:kubernetes_tokens, false)

    # Start fresh before import
    KubernetesToken.delete_all

    # Cluster lookup
    clusters = KubernetesCluster.all.reduce({}) {|acc, i| acc[i.name] = i; acc}

    puts "===== IMPORTING USER TOKENS ====="

    User.all.find_each(batch_size: BATCH_SIZE).each do |u|
      user_kubernetes_identity = u.kubernetes_identity

      data = user_kubernetes_identity.try(:data)
      if data.blank? || !data.has_key?('tokens')
        puts "-- Token data not present for user #{u.id}. Skipping user."
        next
      end

      data['tokens'].each do |t|
        cluster_name = t['cluster']

        if clusters[cluster_name].nil?
          puts "-- Token cluster with name `#{cluster_name}` doesn't exist (user #{u.id} has token defined for `#{cluster_name}` cluster). Skipping token."
          next
        end

        begin
          nt = user_kubernetes_identity.tokens.create!(
            name: u.email,
            cluster: clusters[cluster_name],
            token: ENCRYPTOR.decrypt(t['token']),
            uid: t['uid'],
            groups: t['groups']
          )

          AuditService.log(
            action: 'create',
            auditable: nt,
            data: {
              cluster: cluster_name
            }
          )

          puts "-- Token imported for user #{u.id} and cluster `#{cluster_name}`"
        rescue => e
          puts "-- Token import for user #{u.id} and cluster `#{cluster_name}` failed with #{e.message}"
        end
      end
    end

    puts "===== IMPORTING ROBOT TOKENS ====="

    default_user = User.admin.first

    clusters.each do |cluster_name, cluster|

      hr = HashRecord.kubernetes.find_by id: "#{cluster_name}-static-robot-tokens"
      if hr.try(:data).present?
        hr.data.each do |t|
          begin
            user = t['user_id'].present? ? User.find(t['user_id']) : default_user

            rt = user.robot_tokens.create!(
              name: t['user'],
              cluster: cluster,
              token: ENCRYPTOR.decrypt(t['token']),
              uid: t['uid'],
              groups: t['groups'],
              description: t['description'] || t['user']
            )

            AuditService.log(
              action: 'create',
              auditable: rt,
              data: {
                cluster: cluster_name
              }
            )

            puts "-- Robot token `#{t['user']}` imported for cluster `#{cluster_name}`"
          rescue => e
            puts "-- Robot token `#{t['user']}` import for cluster `#{cluster_name}` failed with #{e.message}"
          end
        end
      end

    end 

    # Enable kubernetes tokens feature flag
    FeatureFlagService.create_or_update(:kubernetes_tokens, true)
  end
end
