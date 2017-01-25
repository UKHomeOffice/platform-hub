export const IdentitiesManagerComponent = {
  template: require('./identities-manager.html'),
  controller: IdentitiesManagerController
};

function IdentitiesManagerController($scope, $mdDialog, hubApiService, gitHubIdentityService, events, _) {
  'ngInject';

  const ctrl = this;

  ctrl.supported = [
    {provider: 'keycloak', title: 'Keycloak (using Office 365)', external: false},
    {provider: 'github', title: 'GitHub', external: true}
  ];

  ctrl.identities = {};

  ctrl.connect = connect;
  ctrl.disconnect = disconnect;

  init();

  function init() {
    // Listen for changes to the Me profile data
    $scope.$on(events.api.me.updated, (event, meData) => {
      processMeData(meData);
    });

    hubApiService.getMe();
  }

  function connect(service) {
    // Currently only support Github
    if (service !== 'github') {
      return;
    }

    gitHubIdentityService
      .popupFlow()
      .then(hubApiService.getMe);
  }

  function disconnect(service, targetEvent) {
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
        hubApiService
          .deleteMeIdentity(service)
          .then(hubApiService.getMe);
      });
  }

  function processMeData(meData) {
    if (_.isEmpty(meData)) {
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
