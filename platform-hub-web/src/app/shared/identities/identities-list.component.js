export const IdentitiesListComponent = {
  bindings: {
    busy: '=',
    onlySelfService: '<'
  },
  template: require('./identities-list.html'),
  controller: IdentitiesListController
};

function IdentitiesListController($mdDialog, Identities, Me, _) {
  'ngInject';

  const ctrl = this;

  ctrl.Identities = Identities;

  ctrl.userIdentities = {};

  ctrl.connect = connect;
  ctrl.disconnect = disconnect;

  init();

  function init() {
    ctrl.busy = true;

    Me
      .refresh()
      .then(processMeData)
      .finally(() => {
        ctrl.busy = false;
      });
  }

  function connect(provider) {
    ctrl.busy = true;

    Me
      .connectIdentity(provider)
      .then(processMeData)
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
          .then(processMeData)
          .finally(() => {
            ctrl.busy = false;
          });
      });
  }

  function processMeData(meData) {
    if (_.isNull(meData) || _.isEmpty(meData)) {
      ctrl.userIdentities = [];
    } else {
      const owned = _.keyBy(meData.identities, 'provider');

      ctrl.userIdentities = Identities.supported.map(entry => {
        const match = _.clone(owned[entry.provider] || {});
        return _.extend(
          _.clone(entry),
          match,
          {connected: !_.isEmpty(match)}
        );
      });
    }
  }
}
