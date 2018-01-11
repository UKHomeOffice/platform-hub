export const roleCheckerService = function ($q, authService, Me, _) {
  'ngInject';

  const service = {};

  service.hasHubRole = hasHubRole;

  return service;

  function hasHubRole(roleOrAllowedRoles) {
    const roles = _.flatten([roleOrAllowedRoles]);
    if (authService.isAuthenticated()) {
      return Me
        .refresh()
        .then(meData => {
          return _.includes(roles, meData.role);
        });
    }

    return $q.resolve(false);
  }
};
