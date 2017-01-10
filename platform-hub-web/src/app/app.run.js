export const appRun = function ($rootScope, $transitions, authService, loginDialogService, logger, _) {
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
};
