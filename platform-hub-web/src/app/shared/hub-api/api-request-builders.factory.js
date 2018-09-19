export const apiRequestBuilders = function ($q, $http, apiEndpoint, apiHelpers, apiPagination, logger, _) {
  'ngInject';

  const buildErrorMessageFromResponse = apiHelpers.buildErrorMessageFromResponse;
  const handleHttpError = apiHelpers.handleHttpError;

  const withPaginationParams = apiPagination.withPaginationParams;
  const handlePaginatedResponse = apiPagination.handlePaginatedResponse;

  return {
    buildSimpleFetcher,
    buildSimplePoster,
    buildSimpleUpdater,
    buildCollectionFetcher,
    buildSubCollectionFetcher,
    buildSubSubCollectionFetcher,
    buildResourceFetcher,
    buildSubResourceFetcher,
    buildSubSubResourceFetcher,
    buildResourceCreator,
    buildSubResourceCreator,
    buildResourceUpdater,
    buildSubResourceUpdater,
    buildResourceDeletor,
    buildSubResourceDeletor
  };

  function buildSimpleFetcher(path, errorDescriptor) {
    return function (params = {}) {
      return $http
        .get(`${apiEndpoint}/${path}`, {
          params
        })
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to fetch ${errorDescriptor}`, response));
          return $q.reject(response);
        });
    };
  }

  function buildSimplePoster(path, errorDescriptor, dataRequired = true) {
    return function (data) {
      if (dataRequired && (_.isNull(data) || _.isEmpty(data))) {
        throw new Error('"data" argument not specified or empty, when it\'s required');
      }

      return $http
        .post(`${apiEndpoint}/${path}`, data)
        .then(handleHttpError)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to ${errorDescriptor}`, response));
          return $q.reject(response);
        });
    };
  }

  function buildSimpleUpdater(path, errorDescriptor) {
    return function (data) {
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

      return $http
        .put(`${apiEndpoint}/${path}`, data)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to update ${errorDescriptor}`, response));
          return $q.reject(response);
        });
    };
  }

  function buildCollectionFetcher(name, isPaginated = false) {
    return function (page = 1, params = {}) {
      return $http
        .get(`${apiEndpoint}/${name}`, {
          params: withPaginationParams(params, isPaginated ? page : null)
        })
        .then(handlePaginatedResponse)
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to fetch items', response));
          return $q.reject(response);
        });
    };
  }

  function buildSubCollectionFetcher(parent, name, isPaginated = false) {
    return function (parentId, page = 1, params = {}) {
      if (_.isNull(parentId) || _.isEmpty(parentId)) {
        throw new Error('"parentId" argument not specified or empty');
      }

      return $http
        .get(`${apiEndpoint}/${parent}/${parentId}/${name}`, {
          params: withPaginationParams(params, isPaginated ? page : null)
        })
        .then(handlePaginatedResponse)
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to fetch items`, response));
          return $q.reject(response);
        });
    };
  }

  function buildSubSubCollectionFetcher(parent, sub, subSub, isPaginated = false) {
    return function (parentId, subId, page = 1, params = {}) {
      if (_.isNull(parentId) || _.isEmpty(parentId)) {
        throw new Error('"parentId" argument not specified or empty');
      }
      if (_.isNull(subId) || _.isEmpty(subId)) {
        throw new Error('"subId" argument not specified or empty');
      }

      return $http
        .get(
          `${apiEndpoint}/${parent}/${parentId}/${sub}/${subId}/${subSub}`, {
            params: withPaginationParams(params, isPaginated ? page : null)
          }
        )
        .then(handlePaginatedResponse)
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to fetch items`, response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceFetcher(resource) {
    return function (id) {
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }

      return $http
        .get(`${apiEndpoint}/${resource}/${id}`)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to fetch item', response));
          return $q.reject(response);
        });
    };
  }

  function buildSubResourceFetcher(parent, resource) {
    return function (parentId, id) {
      if (_.isNull(parentId) || _.isEmpty(parentId)) {
        throw new Error('"parentId" argument not specified or empty');
      }
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }

      return $http
        .get(`${apiEndpoint}/${parent}/${parentId}/${resource}/${id}`)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to fetch item', response));
          return $q.reject(response);
        });
    };
  }

  function buildSubSubResourceFetcher(parent, sub, subSub) {
    return function (parentId, subId, subSubId) {
      if (_.isNull(parentId) || _.isEmpty(parentId)) {
        throw new Error('"parentId" argument not specified or empty');
      }
      if (_.isNull(subId) || _.isEmpty(subId)) {
        throw new Error('"subId" argument not specified or empty');
      }
      if (_.isNull(subSubId) || _.isEmpty(subSubId)) {
        throw new Error('"subSubId" argument not specified or empty');
      }

      return $http
        .get(`${apiEndpoint}/${parent}/${parentId}/${sub}/${subId}/${subSub}/${subSubId}`)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to fetch item`, response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceCreator(resource) {
    return function (data) {
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

      return $http
        .post(`${apiEndpoint}/${resource}`, data)
        .then(handleHttpError)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to create item', response));
          return $q.reject(response);
        });
    };
  }

  function buildSubResourceCreator(parent, resource) {
    return function (parentId, data) {
      if (_.isNull(parentId) || _.isEmpty(parentId)) {
        throw new Error('"parentId" argument not specified or empty');
      }
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

      return $http
        .post(`${apiEndpoint}/${parent}/${parentId}/${resource}`, data)
        .then(handleHttpError)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to create item', response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceUpdater(resource) {
    return function (id, data) {
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

      return $http
        .put(`${apiEndpoint}/${resource}/${id}`, data)
        .then(handleHttpError)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to update item', response));
          return $q.reject(response);
        });
    };
  }

  function buildSubResourceUpdater(parent, resource) {
    return function (parentId, id, data) {
      if (_.isNull(parentId) || _.isEmpty(parentId)) {
        throw new Error('"parentId" argument not specified or empty');
      }
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

      return $http
        .put(`${apiEndpoint}/${parent}/${parentId}/${resource}/${id}`, data)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to update item', response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceDeletor(resource) {
    return function (id) {
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }

      return $http
        .delete(`${apiEndpoint}/${resource}/${id}`)
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to delete item', response));
          return $q.reject(response);
        });
    };
  }

  function buildSubResourceDeletor(parent, resource) {
    return function (parentId, id) {
      if (_.isNull(parentId) || _.isEmpty(parentId)) {
        throw new Error('"parentId" argument not specified or empty');
      }
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }

      return $http
        .delete(`${apiEndpoint}/${parent}/${parentId}/${resource}/${id}`)
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to delete item', response));
          return $q.reject(response);
        });
    };
  }
};
