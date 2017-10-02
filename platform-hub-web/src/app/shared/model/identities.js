export const Identities = function (AppSettings, hubApiService) {
  'ngInject';

  const model = {};

  model.supported = [
    {
      provider: 'keycloak',
      title: 'Keycloak (using Office 365)',
      selfService: false
    },
    {
      provider: 'github',
      title: 'GitHub',
      selfService: true
    },
    {
      provider: 'kubernetes',
      title: 'Kubernetes',
      selfservice: false
    }
  ];

  model.getUserIdentities = getUserIdentities;
  model.getOther = getOther;

  return model;

  function getUserIdentities(userId) {
    return hubApiService.getUserIdentities(userId);
  }

  function getOther() {
    return AppSettings.getOtherManagedServices();
  }
};
