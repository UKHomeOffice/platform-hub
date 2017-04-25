export const Identities = function () {
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
    }
  ];

  return model;
};
