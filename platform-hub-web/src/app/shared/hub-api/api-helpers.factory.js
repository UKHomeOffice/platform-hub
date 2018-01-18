/* eslint camelcase: 0, object-shorthand: 0 */

export const apiHelpers = function ($q, apiDefaultPerPage, _) {
  'ngInject';

  return {
    buildErrorMessageFromResponse,
    handle4xxError,
    withPaginationParams,
    handlePaginatedResponse
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

  function withPaginationParams(params, page) {
    return _.merge(
      params,
      {
        per_page: apiDefaultPerPage,
        page: page
      }
    );
  }

  function handlePaginatedResponse(response) {
    const items = response.data;

    const headers = response.headers();

    if (headers.total && headers['per-page']) {
      items.pagination = {
        total: parseInt(headers.total, 10),
        perPage: parseInt(headers['per-page'], 10)
      };
    }

    return items;
  }
};
