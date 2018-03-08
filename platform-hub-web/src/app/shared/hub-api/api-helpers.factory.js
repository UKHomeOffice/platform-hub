export const apiHelpers = function ($q, _) {
  'ngInject';

  return {
    buildErrorMessageFromResponse,
    handleHttpError
  };

  function buildErrorMessageFromResponse(prefix, response) {
    const errorDetails = _.get(response.data, 'error.message');
    let msg = prefix;
    if (errorDetails) {
      msg += `: ${errorDetails}`;
    }
    return msg;
  }

  function handleHttpError(response) {
    // handle HTTP errors which are not handled by $http.post etc.
    if (response.status >= 400) {
      return $q.reject(response);
    }
    return response;
  }
};
