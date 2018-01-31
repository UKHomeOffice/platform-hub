export const apiHelpers = function ($q, _) {
  'ngInject';

  return {
    buildErrorMessageFromResponse,
    handle4xxError
  };

  function buildErrorMessageFromResponse(prefix, response) {
    const errorDetails = _.get(response.data, 'error.message');
    let msg = prefix;
    if (errorDetails) {
      msg += `: ${errorDetails}`;
    }
    return msg;
  }

  function handle4xxError(response) {
    // handle 4xx errors which are not handled by $http.post
    if (response.status.toString().match(/4../)) {
      return $q.reject(response);
    }
    return response;
  }
};
