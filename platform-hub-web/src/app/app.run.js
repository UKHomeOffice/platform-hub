export const appRun = function ($q, $rootScope, $transitions, $state, authService, loginDialogService, roleCheckerService, events, AppSettings, Me, FeatureFlags, logger, _) {
  'ngInject';

  logger.debug('Starting app…');

  // Inject lodash into templates that have rootScope access.
  $rootScope._ = _;

  // Fetch public AppSettings and inject into templates that have rootScope access.
  AppSettings
    .refresh()
    .then(() => {
      $rootScope.AppSettings = AppSettings;
    });

  // Fetch feature flags now if user is logged in (otherwise they will be
  // fetched later when user does log in).
  if (authService.isAuthenticated()) {
    FeatureFlags.refresh();
  }

  // Listen for auth data change and react accordingly.
  const authDataHandler = $rootScope.$on(events.auth.updated, () => {
    Me.clear();

    if (authService.isAuthenticated()) {
      Me.refresh();
      FeatureFlags.refresh();
    }
  });
  $rootScope.$on('$destroy', authDataHandler);

  // ---------------------------------------------------------------------------
  // Handle transitions to states – this takes into account authentication,
  // feature flags and role checks.
  //
  // See the app.routes.spec.js file for the expected rules.

  function onFail() {
    return $state.target('home');
  }

  function reject() {
    return $q.reject();
  }

  function authenticationChecker() {
    if (authService.isAuthenticated()) {
      return $q.resolve(true);
    }

    return loginDialogService
      .run()
      .catch(reject);
  }

  function featureFlagChecker(flag) {
    return FeatureFlags
      .refresh()
      .then(() => {
        if (FeatureFlags.isEnabled(flag)) {
          return $q.resolve(true);
        }
        return reject();
      })
      .catch(reject);
  }

  function roleChecker(role) {
    return roleCheckerService
      .hasHubRole(role)
      .then(hasRole => {
        if (hasRole) {
          return $q.resolve(true);
        }
        return reject();
      })
      .catch(reject);
  }

  $transitions.onStart({}, transition => {
    const config = transition.$to().data;

    const shouldAuthenticate = Boolean(config.authenticate);

    const shouldCheckFeatureFlag = _.has(config, 'featureFlag');
    const featureFlag = config.featureFlag;

    const shouldCheckRole = _.has(config, 'rolePermitted');
    const rolePermitted = config.rolePermitted;

    // Assumption: if the route doesn't need authentication, then no other
    // config option is supported and checked.

    if (shouldAuthenticate) {
      return authenticationChecker()
        .then(() => {
          if (shouldCheckFeatureFlag) {
            return featureFlagChecker(featureFlag);
          }
          return true;
        })
        .then(() => {
          if (shouldCheckRole) {
            return roleChecker(rolePermitted);
          }
          return true;
        })
        .catch(onFail);
    }
  });
};
