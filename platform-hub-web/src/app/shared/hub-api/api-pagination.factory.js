/* eslint camelcase: 0, object-shorthand: 0 */

export const apiPagination = function (_) {
  'ngInject';

  const DEFAULT_PER_PAGE = 10;

  let perPage;

  resetPerPage();

  return {
    setPerPage,
    resetPerPage,
    withPaginationParams,
    handlePaginatedResponse
  };

  function setPerPage(num) {
    perPage = num;
  }

  function resetPerPage() {
    perPage = DEFAULT_PER_PAGE;
  }

  function withPaginationParams(params, page) {
    if (page) {
      return _.merge(
        params,
        {
          per_page: perPage,
          page: page
        }
      );
    }

    return params;
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
