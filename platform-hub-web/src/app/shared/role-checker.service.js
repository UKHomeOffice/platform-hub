export const roleCheckerService = function (hubApiService) {
  'ngInject';

  const service = {};

  service.hasHubRole = hasHubRole;

  return service;

  function hasHubRole(role) {
    return hubApiService
      .getMe()
      .then(meData => {
        return meData.role === role;
      });
  }
};
