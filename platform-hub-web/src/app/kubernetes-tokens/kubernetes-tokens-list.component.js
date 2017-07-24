export const KubernetesTokensListComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-tokens-list.html'),
  controller: KubernetesTokensListController
};

function KubernetesTokensListController($state, roleCheckerService, hubApiService, logger, $mdDialog, _, KubernetesClusters, icons) {
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

  ctrl.menuIcon = icons.menu;
  ctrl.syncTokensIcon = icons.syncTokens;
  ctrl.addTokenIcon = icons.addToken;
  ctrl.revokeTokenIcon = icons.revokeToken;

  ctrl.searchUsers = searchUsers;
  ctrl.deleteToken = deleteToken;
  ctrl.filterKubernetesTokensByUser = filterKubernetesTokensByUser;
  ctrl.revokeToken = revokeToken;

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
    if (ctrl.searchSelectedUser) {
      loadUserAndTokens(ctrl.searchSelectedUser.id);
    }
  }

  function loadUserAndTokens(userId) {
    return hubApiService
      .getUser(userId)
      .then(user => {
        ctrl.user = user;
        return fetchKubernetesTokens();
      });
  }

  function fetchKubernetesTokens() {
    ctrl.tokens = [];

    const identity = _.find(ctrl.user.identities, ['provider', 'kubernetes']);

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
    return hubApiService.searchUsers(query, true);
  }

  function revokeToken(targetEvent) {
    const confirm = $mdDialog.prompt()
      .title('Revoke kubernetes token')
      .textContent('This will revoke existing kubernetes token entirely.')
      .placeholder('Kubernetes token you would like to revoke')
      .ariaLabel('Revoke token')
      .initialValue('')
      .targetEvent(targetEvent)
      .ok('Revoke token')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(revokedToken => {
        if (_.isNull(revokedToken) || _.isEmpty(revokedToken)) {
          logger.error('Kubernetes token not specified or empty!');
        } else {
          ctrl.busy = true;
          hubApiService
            .revokeKubernetesToken({token: revokedToken})
            .then(() => {
              logger.success('Kubernetes token revoked successfully!');
              $state.reload();
            })
            .finally(() => {
              ctrl.busy = false;
            });
        }
      });
  }
}
