export const KubernetesNamespacesListComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-namespaces-list.html'),
  controller: KubernetesNamespacesListController
};

function KubernetesNamespacesListController($state, $mdSelect, $mdDialog, KubernetesClusters, KubernetesNamespaces, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.KubernetesNamespaces = KubernetesNamespaces;

  ctrl.loading = true;
  ctrl.busy = false;
  ctrl.cluster = ctrl.transition && ctrl.transition.params().cluster;
  ctrl.namespaces = [];

  ctrl.handleClusterChange = handleClusterChange;
  ctrl.deleteNamespace = deleteNamespace;

  init();

  function init() {
    ctrl.loading = true;

    KubernetesClusters
      .refresh()
      .then(fetchNamespaces)
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function fetchNamespaces() {
    ctrl.namespaces = [];

    if (ctrl.cluster) {
      ctrl.busy = true;

      return KubernetesNamespaces
        .getAllByCluster(ctrl.cluster)
        .then(namespaces => {
          angular.copy(namespaces, ctrl.namespaces);
        })
        .finally(() => {
          ctrl.busy = false;
        });
    }
  }

  function handleClusterChange() {
    // See: https://github.com/angular/material/issues/10747
    $mdSelect.hide().then(() => {
      $state.go('kubernetes.namespaces.list', {cluster: ctrl.cluster});
    });
  }

  function deleteNamespace(namespaceId, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete this kubernetes namespace from the hub. NOTE: this doesn\'t actually delete the namespace from the cluster - it just deletes the entry in the hub.')
      .ariaLabel('Confirm deletion of a kubernetes namespace from the hub')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.busy = true;

        KubernetesNamespaces
          .delete(namespaceId)
          .then(() => {
            logger.success('Namespace deleted');
            return fetchNamespaces();
          })
          .finally(() => {
            ctrl.busy = false;
          });
      });
  }
}
