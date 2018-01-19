export const KubernetesGroupsListComponent = {
  template: require('./kubernetes-groups-list.html'),
  controller: KubernetesGroupsListController
};

function KubernetesGroupsListController(KubernetesGroups) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.groups = [];

  ctrl.fetchGroups = fetchGroups;

  init();

  function init() {
    fetchGroups();
  }

  function fetchGroups(page = 1) {
    ctrl.loading = true;

    return KubernetesGroups
      .list(page)
      .then(groups => {
        ctrl.groups = groups;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
