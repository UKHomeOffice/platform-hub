export const apiInterceptorService = function ($q, $rootScope, events) {
  'ngInject';

  const service = {};

  service.responseError = responseError;

  return service;

  function responseError(response) {
    if (response.status === 401) {
      $rootScope.$broadcast(events.auth.unauthorized, 'User unauthorized');
    }
    if (response.status === 403) {
      $rootScope.$broadcast(events.auth.forbidden, 'Access forbidden');
    }
    if (response.status === 404) {
      $rootScope.$broadcast(events.api.resourceNotFound, 'Not found');
    }
    if (response.status === 418) {
      $rootScope.$broadcast(events.auth.deactivated, 'User deactivated');
    }
    return $q.reject(response);
  }
};
