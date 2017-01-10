export const authService = function ($window, $cookies, $q, $filter, $base64, $state, $rootScope, jwtHelper, windowPopupService, apiEndpoint, logger, _) {
  'ngInject';

  const authEndpoint = `${apiEndpoint}/oauth`;
  const completionUrl = $state.href('home', {}, {absolute: true});
  const completionUrlEncoded = $filter('bcEncode')($base64.encode(completionUrl));

  const popupClosePredicateFn = function (win) {
    return win.location.href === completionUrl;
  };

  const accessCookieName = 'auth-access';
  const authDataEvent = 'auth:data';

  const popupHeight = 500;
  const popupWidth = 500;

  const service = {};

  service.authenticate = authenticate;
  service.logout = logout;
  service.isAuthenticated = isAuthenticated;
  service.getToken = getToken;
  service.getPayload = getPayload;

  return service;

  function authenticate() {
    return windowPopupService.open(
      `${authEndpoint}/authorize?state=${completionUrlEncoded}`,
      'authPopup',
      windowPopupOptions(),
      popupClosePredicateFn
    ).then(() => {
      broadcastAuthData();

      if (!isAuthenticated()) {
        logger.error('Failed to login');
        return $q.reject();
      }

      logger.success('Logged in successfully');
    });
  }

  function logout() {
    return windowPopupService.open(
      `${authEndpoint}/logout?redirect=${completionUrlEncoded}`,
      'logoutPopup',
      windowPopupOptions(),
      popupClosePredicateFn
    ).then(() => {
      broadcastAuthData();

      if (isAuthenticated()) {
        logger.error('Failed to log you out');
        return $q.reject();
      }

      logger.success('Logged out');
    });
  }

  function isAuthenticated() {
    const token = getToken();

    if (_.isEmpty(token)) {
      return false;
    }

    let isExpired = true;
    try {
      isExpired = jwtHelper.isTokenExpired(token);
    } catch (e) {
      logger.debug('Failed to parse JWT token: ');
      logger.debug(e);
    }

    return !isExpired;
  }

  function getToken() {
    return $cookies.get(accessCookieName);
  }

  function getPayload() {
    const token = getToken();

    if (_.isEmpty(token)) {
      return null;
    }

    try {
      return jwtHelper.decodeToken(token);
    } catch (e) {
      logger.debug('Failed to parse JWT token: ');
      logger.debug(e);
      return null;
    }
  }

  function windowPopupOptions() {
    return {
      width: popupHeight,
      height: popupWidth,
      top: $window.screenY + (($window.outerHeight - popupHeight) / 2.5),
      left: $window.screenX + (($window.outerWidth - popupWidth) / 2)
    };
  }

  function broadcastAuthData() {
    $rootScope.$broadcast(authDataEvent, getPayload());
  }
};
