export const KubernetesGroupsListComponent = {
  template: require('./kubernetes-groups-list.html'),
  controller: KubernetesGroupsListController
};

function KubernetesGroupsListController(KubernetesGroups) {
  'ngInject';

  const ctrl = this;

  ctrl.KubernetesGroups = KubernetesGroups;

  init();

  function init() {
    ctrl.loading = true;

    KubernetesGroups
      .refresh()
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
