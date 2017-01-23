export const gitHubIdentityService = function (windowPopupService, apiEndpoint, homeEndpoint) {
  'ngInject';

  const service = {};

  service.popupFlow = popupFlow;

  return service;

  function popupFlow() {
    return windowPopupService.open(
      `${apiEndpoint}/identity_flows/start/github`,
      'githubIdentityFlowPopup',
      {},
      homeEndpoint
    );
  }
};
