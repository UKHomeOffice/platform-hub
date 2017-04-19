export const roleCheckerService = function ($q, authService, Me) {
  'ngInject';

  const service = {};

  service.hasHubRole = hasHubRole;

  return service;

  function hasHubRole(role) {
    if (authService.isAuthenticated()) {
      return Me
        .refresh()
        .then(meData => {
          return meData.role === role;
        });
    }

    return $q.resolve(false);
  }
};
