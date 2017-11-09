export const KubernetesUserTokensListComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-user-tokens-list.html'),
  controller: KubernetesUserTokensListController
};

function KubernetesUserTokensListController($state, roleCheckerService, hubApiService, logger, $mdDialog, _, Identities, KubernetesClusters, KubernetesTokens, icons, kubernetesTokenEscalatePrivilegePopupService) {
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
  ctrl.escalatePrivilege = escalatePrivilege;
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

        if (!ctrl.searchSelectedUser) {
          ctrl.searchSelectedUser = user;
        }

        return fetchKubernetesTokens();
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

  function escalatePrivilege(tokenId, targetEvent) {
    kubernetesTokenEscalatePrivilegePopupService.open(
      tokenId,
      targetEvent
    ).then(filterKubernetesTokensByUser);
  }

  function deleteToken(tokenId, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title(`Are you sure?`)
      .textContent(`This will delete selected token.`)
      .ariaLabel('Confirm token removal')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        KubernetesTokens
          .deleteToken(tokenId)
          .then(() => {
            loadUserAndTokens(ctrl.user.id);
          });
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
