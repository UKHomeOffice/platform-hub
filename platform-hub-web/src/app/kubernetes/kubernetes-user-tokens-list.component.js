export const KubernetesUserTokensListComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-user-tokens-list.html'),
  controller: KubernetesUserTokensListController
};

function KubernetesUserTokensListController($state, roleCheckerService, hubApiService, logger, $mdDialog, _, Identities, KubernetesTokens, icons) {
  'ngInject';

  const ctrl = this;
  const userId = ctrl.transition && ctrl.transition.params().userId;

  ctrl.loading = true;
  ctrl.busy = false;
  ctrl.tokens = [];
  ctrl.searchSelectedUser = null;
  ctrl.searchText = '';
  ctrl.user = null;

  ctrl.menuIcon = icons.menu;
  ctrl.syncTokensIcon = icons.syncTokens;
  ctrl.addTokenIcon = icons.addToken;
  ctrl.revokeTokenIcon = icons.revokeToken;

  ctrl.fetchUserAndTokens = fetchUserAndTokens;
  ctrl.searchUsers = searchUsers;
  ctrl.revokeToken = revokeToken;

  init();

  function init() {
    if (userId) {
      fetchUserAndTokens();
    } else {
      ctrl.loading = false;
    }
  }

  function fetchUserAndTokens() {
    ctrl.loading = true;

    let selectedUserId = userId;
    // … but if we have a user from search then use that
    if (ctrl.searchSelectedUser) {
      selectedUserId = ctrl.searchSelectedUser.id;
    }

    return hubApiService
      .getUser(selectedUserId)
      .then(user => {
        ctrl.user = user;

        if (!ctrl.searchSelectedUser) {
          ctrl.searchSelectedUser = user;
        }

        return fetchKubernetesTokens();
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function fetchKubernetesTokens() {
    ctrl.tokens = [];

    return Identities
      .getUserIdentities(ctrl.user.id)
      .then(identities => {
        const identity = _.find(identities, ['provider', 'kubernetes']);

        if (identity) {
          ctrl.tokens = identity.kubernetes_tokens;
        }
      });
  }

  function searchUsers(query) {
    return hubApiService.searchUsers(query, true);
  }

  function revokeToken(targetEvent) {
    const confirm = $mdDialog.prompt()
      .title('Revoke kubernetes token')
      .textContent('This will revoke an existing Kubernetes token using the token value provided.')
      .placeholder('Kubernetes token value you would like to revoke')
      .ariaLabel('Revoke token')
      .initialValue('')
      .targetEvent(targetEvent)
      .ok('Revoke token')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(tokenValueToRevoke => {
        if (_.isNull(tokenValueToRevoke) || _.isEmpty(tokenValueToRevoke)) {
          logger.error('Kubernetes token not specified or empty!');
        } else {
          ctrl.busy = true;
          KubernetesTokens
            .revokeToken(tokenValueToRevoke)
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
