export const Identities = function (AppSettings) {
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

  model.getOther = getOther;

  return model;

  function getOther() {
    return AppSettings.getOtherManagedServices();
  }
};
