export const KubernetesTokensListComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-tokens-list.html'),
  controller: KubernetesTokensListController
};

function KubernetesTokensListController($state, roleCheckerService, hubApiService, logger, $mdDialog, _, KubernetesClusters) {
  'ngInject';

  const ctrl = this;
  const userId = ctrl.transition && ctrl.transition.params().userId;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.searchSelectedUser = null;
  ctrl.loading = true;
  ctrl.busy = false;
  ctrl.tokens = [];
  ctrl.searchText = '';
  ctrl.user = null;

  ctrl.searchUsers = searchUsers;
  ctrl.deleteToken = deleteToken;
  ctrl.filterKubernetesTokensByUser = filterKubernetesTokensByUser;

  init();

  function init() {
    ctrl.loading = true;

    KubernetesClusters
      .refresh()
      .then(() => {
        if (userId) {
          return loadUserAndTokens(userId);
        }
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function filterKubernetesTokensByUser() {
    loadUserAndTokens(ctrl.searchSelectedUser.id);
  }

  function loadUserAndTokens(user) {
    return hubApiService
      .getUser(user)
      .then(user => {
        ctrl.user = user;
        fetchKubernetesTokens();
      });
  }

  function fetchKubernetesTokens() {
    ctrl.tokens = [];

    // const identity = _.find(ctrl.user.identities, i => {
    //   return i.provider === 'kubernetes';
    // });
    const identity = _.find(ctrl.user.identities, 'provider', 'kubernetes');

    if (identity) {
      ctrl.tokens = identity.kubernetes_tokens;
    }
  }

  function deleteToken(userId, cluster, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title(`Are you sure?`)
      .textContent(`This will delete the "${cluster}" token.`)
      .ariaLabel('Confirm token removal')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        hubApiService
          .deleteKubernetesToken(userId, cluster)
          .then(() => {
            loadUserAndTokens(userId);
          });
      });
  }

  function searchUsers(query) {
    return hubApiService.searchUsers(query);
  }
}
