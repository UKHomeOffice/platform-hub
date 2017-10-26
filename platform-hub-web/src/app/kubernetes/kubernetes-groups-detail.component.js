export const KubernetesGroupsDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-groups-detail.html'),
  controller: KubernetesGroupsDetailController
};

function KubernetesGroupsDetailController($mdDialog, $state, KubernetesGroups, projectServiceSelectorPopupService, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.group = null;
  ctrl.allocations = [];
  ctrl.loadingAllocations = false;

  ctrl.deleteGroup = deleteGroup;
  ctrl.allocate = allocate;
  ctrl.loadAllocations = loadAllocations;

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

  function allocate(targetEvent) {
    return projectServiceSelectorPopupService
      .openForProjectOrService(targetEvent)
      .then(result => {
        if (result.service) {
          return KubernetesGroups.allocateToService(
            ctrl.group.id,
            result.project.id,
            result.service.id
          );
        }

        return KubernetesGroups.allocateToProject(
          ctrl.group.id,
          result.project.id
        );
      })
      .then(() => {
        logger.success('Successfully allocated this Kubernetes RBAC group');
        loadAllocations();
      });
  }

  function loadAllocations() {
    ctrl.loadingAllocations = true;

    return KubernetesGroups
      .getAllocations(ctrl.group.id)
      .then(allocations => {
        angular.copy(allocations, ctrl.allocations);
      })
      .finally(() => {
        ctrl.loadingAllocations = false;
      });
  }
}
