export const IdentitiesListComponent = {
  bindings: {
    busy: '=',
    onlySelfService: '<',
    expandOtherServices: '<'
  },
  template: require('./identities-list.html'),
  controller: IdentitiesListController
};

function IdentitiesListController($mdDialog, Identities, Me, _, FeatureFlags, featureFlagKeys, kubernetesIdentityTokensPopupService) {
  'ngInject';

  const ctrl = this;

  ctrl.Identities = Identities;
  ctrl.FeatureFlags = FeatureFlags;
  ctrl.featureFlagKeys = featureFlagKeys;

  ctrl.currentUserId = null;
  ctrl.userIdentities = {};

  ctrl.connect = connect;
  ctrl.disconnect = disconnect;
  ctrl.showKubernetesTokens = showKubernetesTokens;

  init();

  function init() {
    ctrl.busy = true;

    if (Me.data.id) {
      ctrl.currentUserId = Me.data.id;
      refresh();
    } else {
      Me
        .refresh()
        .then(meData => {
          ctrl.currentUserId = meData.id;
          return refresh();
        });
    }
  }

  function refresh() {
    ctrl.busy = true;

    Identities
      .getUserIdentities(ctrl.currentUserId)
      .then(identities => {
        if (_.isNull(identities) || _.isEmpty(identities)) {
          ctrl.userIdentities = [];
        } else {
          const owned = _.keyBy(identities, 'provider');

          ctrl.userIdentities = Identities.supported.map(entry => {
            const match = _.clone(owned[entry.provider] || {});
            return _.extend(
              _.clone(entry),
              match,
              {connected: !_.isEmpty(match)}
            );
          });
        }
      })
      .finally(() => {
        ctrl.busy = false;
      });
  }

  function connect(provider) {
    ctrl.busy = true;

    Me
      .connectIdentity(provider)
      .then(refresh)
      .finally(() => {
        ctrl.busy = false;
      });
  }

  function disconnect(provider, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title(`Are you sure?`)
      .textContent('This will delete the identity permanently from your hub account. Though you can always connect it back up again later.')
      .ariaLabel('Confirm disconnection of identity')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.busy = true;

        Me
          .deleteIdentity(provider)
          .then(refresh)
          .finally(() => {
            ctrl.busy = false;
          });
      });
  }

  function showKubernetesTokens(identity, targetEvent) {
    return kubernetesIdentityTokensPopupService.open(identity, targetEvent);
  }
}
