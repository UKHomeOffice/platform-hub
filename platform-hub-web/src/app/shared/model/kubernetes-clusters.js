import angular from 'angular';

export const KubernetesClusters = function ($window, hubApiService, apiBackoffTimeMs, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.all = [];

  model.refresh = refresh;
  model.get = get;
  model.createOrUpdate = createOrUpdate;

  return model;

  function refresh(force) {
    if (force || _.isNull(fetcherPromise)) {
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

  function get(id) {
    return refresh()
      .then(clusters => {
        return _.find(clusters, ['id', id]);
      });
  }

  function createOrUpdate(id, data) {
    return hubApiService
      .createOrUpdateKubernetesCluster(id, data)
      .then(() => {
        return refresh(true);
      });
  }
};
