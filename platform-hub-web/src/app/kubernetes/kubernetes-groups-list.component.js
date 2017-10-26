export const KubernetesGroupsListComponent = {
  template: require('./kubernetes-groups-list.html'),
  controller: KubernetesGroupsListController
};

function KubernetesGroupsListController(KubernetesGroups) {
  'ngInject';

  const ctrl = this;

  ctrl.KubernetesGroups = KubernetesGroups;
  ctrl.loading = true;

  init();

  function init() {
    KubernetesGroups
      .refresh()
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
