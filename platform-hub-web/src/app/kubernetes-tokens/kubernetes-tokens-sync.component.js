export const KubernetesTokensSyncComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-tokens-sync.html'),
  controller: KubernetesTokensSyncController
};

function KubernetesTokensSyncController($state, hubApiService, logger, _, KubernetesClusters, $mdDialog) {
  'ngInject';

  const ctrl = this;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.changes = null;

  ctrl.getChangeset = getChangeset;
  ctrl.syncTokens = syncTokens;

  init();

  function init() {
    ctrl.loading = true;

    // Kubernetes clusters are defined as follows:
    // [
    //   {id: 'cluster1', description: 'Cluster 1'},
    //   {id: 'cluster2', description: 'Cluster 2'},
    //   ...
    // ];
    KubernetesClusters
      .refresh()
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function getChangeset() {
    ctrl.loading = true;
    hubApiService
      .getKubernetesTokensChangeset(ctrl.cluster)
      .then(c => {
        ctrl.changes = c;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function syncTokens(clusterName, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title(`Are you sure?`)
      .textContent(`This will upload tokens to "${clusterName}" cluster.`)
      .ariaLabel('Confirm tokens upload')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.saving = true;
        hubApiService
          .syncKubernetesTokens({cluster: clusterName})
          .then(() => {
            logger.success('Kubernetes tokens synced successfully!');
            getChangeset();
          })
          .finally(() => {
            ctrl.saving = false;
          });
      });
  }
}
