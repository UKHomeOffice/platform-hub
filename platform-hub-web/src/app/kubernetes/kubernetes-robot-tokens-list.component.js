export const KubernetesRobotTokensListComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-robot-tokens-list.html'),
  controller: KubernetesRobotTokensListController
};

function KubernetesRobotTokensListController($q, $state, $mdSelect, icons, KubernetesClusters, KubernetesTokens) {
  'ngInject';

  const ctrl = this;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.addTokenIcon = icons.addToken;

  ctrl.loading = true;
  ctrl.busy = false;
  ctrl.cluster = ctrl.transition && ctrl.transition.params().cluster;
  ctrl.tokens = [];

  ctrl.fetchTokens = fetchTokens;
  ctrl.handleClusterChange = handleClusterChange;

  init();

  function init() {
    ctrl.loading = true;

    KubernetesClusters
      .refresh()
      .then(() => fetchTokens())
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function fetchTokens(page = 1) {
    if (ctrl.cluster) {
      ctrl.busy = true;

      return KubernetesTokens
        .getRobotTokens(ctrl.cluster, page)
        .then(tokens => {
          ctrl.tokens = tokens;
        })
        .finally(() => {
          ctrl.busy = false;
        });
    }
    return $q.when();
  }

  function handleClusterChange() {
    // See: https://github.com/angular/material/issues/10747
    $mdSelect.hide().then(() => {
      $state.go('kubernetes.robot-tokens.list', {cluster: ctrl.cluster});
    });
  }
}
