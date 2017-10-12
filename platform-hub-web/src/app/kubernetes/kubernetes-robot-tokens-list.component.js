export const KubernetesRobotTokensListComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-robot-tokens-list.html'),
  controller: KubernetesRobotTokensListController
};

function KubernetesRobotTokensListController($state, $mdSelect, $mdDialog, hubApiService, icons, KubernetesClusters) {
  'ngInject';

  const ctrl = this;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.addTokenIcon = icons.addToken;

  ctrl.loading = true;
  ctrl.busy = false;
  ctrl.cluster = ctrl.transition && ctrl.transition.params().cluster;
  ctrl.tokens = [];

  ctrl.handleClusterChange = handleClusterChange;
  ctrl.deleteToken = deleteToken;

  init();

  function init() {
    ctrl.loading = true;

    KubernetesClusters
      .refresh()
      .then(fetchTokens)
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function fetchTokens() {
    ctrl.tokens = [];

    if (ctrl.cluster) {
      ctrl.busy = true;

      return hubApiService
        .getKubernetesRobotTokens(ctrl.cluster)
        .then(tokens => {
          angular.copy(tokens, ctrl.tokens);
        })
        .finally(() => {
          ctrl.busy = false;
        });
    }
  }

  function handleClusterChange() {
    // See: https://github.com/angular/material/issues/10747
    $mdSelect.hide().then(() => {
      $state.go('kubernetes.robot-tokens.list', {cluster: ctrl.cluster});
    });
  }

  function deleteToken(tokenId, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title(`Are you sure?`)
      .textContent(`This will delete selected robot token.`)
      .ariaLabel('Confirm token removal')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        hubApiService
          .deleteKubernetesToken(tokenId)
          .then(fetchTokens);
      });
  }
}
