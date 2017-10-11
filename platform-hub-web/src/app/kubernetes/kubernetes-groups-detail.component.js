export const KubernetesGroupsDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-groups-detail.html'),
  controller: KubernetesGroupsDetailController
};

function KubernetesGroupsDetailController($mdDialog, $state, KubernetesGroups, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.group = null;

  ctrl.deleteGroup = deleteGroup;

  init();

  function init() {
    loadGroup();
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

  function deleteGroup(targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the RBAC group from the hub, BUT it won\'t remove it from the cluster and will not affect any existing tokens that have this group.')
      .ariaLabel('Confirm deletion of RBAC group from the hub')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        KubernetesGroups
          .delete(ctrl.group.id)
          .then(() => {
            logger.success('Kubernetes RBAC group deleted from the hub');
            $state.go('kubernetes.groups.list');
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }
}
