export const hubApiService = function ($rootScope, $http, $q, logger, events, apiEndpoint) {
  'ngInject';

  const service = {};

  service.getMe = getMe;
  service.deleteMeIdentity = deleteMeIdentity;

  return service;

  function getMe() {
    return $http
      .get(`${apiEndpoint}/me`)
      .then(response => {
        const me = response.data;

        $rootScope.$broadcast(events.api.me.updated, me);
        logger.debug(me);

        return me;
      })
      .catch(response => {
        logger.error('Faild to fetch profile data – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function deleteMeIdentity(provider) {
    return $http
      .delete(`${apiEndpoint}/me/identities/${provider}`)
      .catch(response => {
        logger.error(`Failed to delete the identity for '${provider}' – the API might be down. Try again later.`);
        return $q.reject(response);
      });
  }
};
