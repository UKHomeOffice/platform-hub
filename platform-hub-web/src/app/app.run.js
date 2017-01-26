export const appRun = function ($rootScope, $transitions, $state, authService, loginDialogService, roleCheckerService, hubApiService, events, logger, _) {
  'ngInject';

  logger.debug('Starting app…');

  // Inject lodash into views
  $rootScope._ = _;

  // Auth handling

  const homeTargetState = $state.target('home');

  function roleChecker(role) {
    return roleCheckerService
      .hasHubRole(role)
      .then(hasRole => {
        if (hasRole) {
          return true;
        }
        return homeTargetState;
      });
  }

  $transitions.onStart({}, transition => {
    const toData = transition.$to().data;

    const shouldAuthenticate = Boolean(toData.authenticate);

    const shouldCheckRole = _.has(toData, 'rolePermitted');
    const rolePermitted = toData.rolePermitted;

    if (shouldAuthenticate && !authService.isAuthenticated()) {
      return loginDialogService()
        .then(() => {
          if (shouldCheckRole) {
            return roleChecker(rolePermitted);
          }
          return true;
        })
        .catch(() => {
          return homeTargetState;
        });
    } else if (shouldCheckRole) {
      return roleChecker(rolePermitted);
    }
  });

  // Listen for auth data change and fetch the Me profile/settings data from the API
  const authDataHandler = $rootScope.$on(events.auth.updated, (event, authData) => {
    if (_.isEmpty(authData)) {
      $rootScope.$broadcast(events.api.me.updated, null);
    } else {
      hubApiService.getMe();
    }
  });
  $rootScope.$on('$destroy', authDataHandler);
};
