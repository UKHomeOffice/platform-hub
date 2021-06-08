export const authService = function ($window, $cookies, $q, $filter, $base64, $rootScope, jwtHelper, windowPopupService, events, apiEndpoint, homeEndpoints, logger, _) {
  'ngInject';

  const authEndpoint = `${apiEndpoint}/oauth`;

  const accessCookieName = 'auth-access';

  const service = {};

  service.authenticate = authenticate;
  service.logout = logout;
  service.isAuthenticated = isAuthenticated;
  service.getToken = getToken;
  service.getPayload = getPayload;

  return service;

  function authenticate() {
    const completionUrl = $filter('bcEncode')($base64.encode(homeEndpoints.homePreload));
    return windowPopupService.open(
      `${authEndpoint}/authorize?state=${completionUrl}`,
      'authPopup',
      {},
      homeEndpoints.home
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
    const completionUrl = $filter('bcEncode')($base64.encode(homeEndpoints.home));
    return windowPopupService.open(
      `${authEndpoint}/logout?redirect=${completionUrl}`,
      'logoutPopup',
      {},
      homeEndpoints.home
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

    if (_.isNull(token) || _.isEmpty(token)) {
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
    let accessCookie = '';

    // if there are multiple cookies with this name, then combine them to get the full cookie
    const allCookies = $cookies.getAll();
    angular.forEach(allCookies, (key, value) => {
      if (key.startsWith(accessCookieName)) {
        accessCookie += value;
      }
    });

    return accessCookie;
  }

  function getPayload() {
    const token = getToken();

    if (_.isNull(token) || _.isEmpty(token)) {
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

  function broadcastAuthData() {
    $rootScope.$broadcast(events.auth.updated, getPayload());
  }
};
