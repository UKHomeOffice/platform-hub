export const IdentitiesManagerComponent = {
  template: require('./identities-manager.html'),
  controller: IdentitiesManagerController
};

function IdentitiesManagerController($scope, hubApiService, gitHubIdentityService, events, _) {
  'ngInject';

  const ctrl = this;

  ctrl.supported = [
    {provider: 'keycloak', title: 'Keycloak (using Office 365)', external: false},
    {provider: 'github', title: 'GitHub', external: true}
  ];

  ctrl.identities = {};

  ctrl.connect = connect;

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
