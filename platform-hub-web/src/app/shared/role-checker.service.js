export const roleCheckerService = function ($q, hubApiService, authService) {
  'ngInject';

  const service = {};

  service.hasHubRole = hasHubRole;

  return service;

  function hasHubRole(role) {
    if (authService.isAuthenticated()) {
      return hubApiService
        .getMe()
        .then(meData => {
          return meData.role === role;
        });
    }

    return $q.resolve(false);
  }
};
