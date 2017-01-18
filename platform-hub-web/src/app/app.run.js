export const appRun = function ($rootScope, $transitions, authService, loginDialogService, hubApiService, logger, _) {
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
  const apiMeEvent = 'api:me';
  const authDataHandler = $rootScope.$on('auth:data', (event, authData) => {
    if (_.isEmpty(authData)) {
      $rootScope.$broadcast(apiMeEvent, null);
    } else {
      hubApiService
        .getMe()
        .then(me => {
          $rootScope.$broadcast(apiMeEvent, me);
          logger.debug(me);
        });
    }
  });
  $rootScope.$on('$destroy', authDataHandler);
};
