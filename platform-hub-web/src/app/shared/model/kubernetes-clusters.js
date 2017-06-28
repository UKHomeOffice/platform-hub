import angular from 'angular';

export const KubernetesClusters = function ($window, hubApiService, apiBackoffTimeMs, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.all = [];

  model.refresh = refresh;

  return model;

  function refresh() {
    if (_.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getKubernetesClusters()
        .then(clusters => {
          angular.copy(clusters, model.all);
          return model.all;
        })
        .finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $window.setTimeout(() => {
            fetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return fetcherPromise;
  }
};
