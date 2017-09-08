export const KubernetesClustersListComponent = {
  template: require('./kubernetes-clusters-list.html'),
  controller: KubernetesClustersListController
};

function KubernetesClustersListController(KubernetesClusters) {
  'ngInject';

  const ctrl = this;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.loading = true;

  init();

  function init() {
    KubernetesClusters
      .refresh()
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
