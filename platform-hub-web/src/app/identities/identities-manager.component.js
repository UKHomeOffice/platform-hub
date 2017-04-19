export const IdentitiesManagerComponent = {
  template: require('./identities-manager.html'),
  controller: IdentitiesManagerController
};

function IdentitiesManagerController($scope, $mdDialog, Me, _) {
  'ngInject';

  const ctrl = this;

  ctrl.supported = [
    {provider: 'keycloak', title: 'Keycloak (using Office 365)', external: false},
    {provider: 'github', title: 'GitHub', external: true}
  ];

  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.identities = {};

  ctrl.connect = connect;
  ctrl.disconnect = disconnect;

  init();

  function init() {
    ctrl.loading = true;

    Me
      .refresh()
      .then(processMeData)
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function connect(provider) {
    // Currently only support Github
    if (provider !== 'github') {
      return;
    }

    ctrl.processing = true;

    Me
      .connectIdentity(provider)
      .then(processMeData)
      .finally(() => {
        ctrl.processing = false;
      });
  }

  function disconnect(provider, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title(`Are you sure?`)
      .textContent('This will delete the identity permanently from your Platform Hub account. Though you can always connect it back up again later.')
      .ariaLabel('Confirm disconnection of identity')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processing = true;

        Me
          .deleteIdentity(provider)
          .then(processMeData)
          .finally(() => {
            ctrl.processing = false;
          });
      });
  }

  function processMeData(meData) {
    if (_.isNull(meData) || _.isEmpty(meData)) {
      ctrl.identities = [];
    } else {
      const owned = _.keyBy(meData.identities, 'provider');

      ctrl.identities = ctrl.supported.map(entry => {
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
