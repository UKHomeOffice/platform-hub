module KubernetesGroupsSubCollection
  extend ActiveSupport::Concern

  # `resource` is expected to have a `#kubernetes_groups` association
  def kubernetes_groups_sub_collection resource, target = nil
    scope = resource.kubernetes_groups.not_privileged
    groups = if target.present?
      unless KubernetesGroup.targets.keys.include?(target)
        bad_request_error('Invalid `target` param specified') and return
      end
      scope.send(target)
    else
      scope
    end

    render json: groups.order(:name)
  end
end
