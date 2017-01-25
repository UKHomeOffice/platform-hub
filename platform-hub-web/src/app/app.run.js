export const appRun = function ($rootScope, $transitions, authService, loginDialogService, hubApiService, events, logger, _) {
  'ngInject';

  logger.debug('Starting app…');

  // Inject lodash into views
  $rootScope._ = _;

  // Auth handling
  $transitions.onStart({}, transition => {
    const $state = transition.router.stateService;

    const shouldAuthenticate = Boolean(transition.$to().data.authenticate);

    if (shouldAuthenticate && !authService.isAuthenticated()) {
      return loginDialogService()
        .catch(() => {
          return $state.target('home');
        });
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
