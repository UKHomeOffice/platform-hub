/* eslint camelcase: 0 */

export const KubernetesGroupsFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-groups-form.html'),
  controller: KubernetesGroupsFormController
};

function KubernetesGroupsFormController($state, KubernetesClusters, KubernetesGroups, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.KubernetesGroups = KubernetesGroups;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.group = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    KubernetesClusters
      .refresh()
      .then(() => {
        if (ctrl.isNew) {
          ctrl.group = initEmptyGroup();
          ctrl.loading = false;
        } else {
          loadGroup();
        }
      });
  }

  function initEmptyGroup() {
    return {
      kind: KubernetesGroups.kinds[0],
      target: KubernetesGroups.targets[0],
      is_privileged: false,
      restricted_to_clusters: []
    };
  }

  function loadGroup() {
    ctrl.loading = true;
    ctrl.group = null;

    KubernetesGroups
      .get(id)
      .then(group => {
        ctrl.group = group;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.groupForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      KubernetesGroups
        .create(ctrl.group)
        .then(group => {
          logger.success('New Kubernetes RBAC group registered');
          $state.go('kubernetes.groups.detail', {id: group.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      KubernetesGroups
        .update(ctrl.group.id, ctrl.group)
        .then(group => {
          logger.success('Kubernetes RBAC group updated');
          $state.go('kubernetes.groups.detail', {id: group.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }
}
