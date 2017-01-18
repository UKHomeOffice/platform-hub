export const hubApiService = function ($http, $q, logger, apiEndpoint) {
  'ngInject';

  const service = {};

  service.getMe = getMe;

  return service;

  function getMe() {
    return $http
      .get(`${apiEndpoint}/me`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error('Faild to fetch profile data – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }
};
