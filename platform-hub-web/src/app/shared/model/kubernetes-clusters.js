import angular from 'angular';

export const KubernetesClusters = function ($timeout, hubApiService, apiBackoffTimeMs, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.all = [];

  model.refresh = refresh;
  model.get = hubApiService.getKubernetesCluster;
  model.create = hubApiService.createKubernetesCluster;
  model.update = hubApiService.updateKubernetesCluster;
  model.allocate = hubApiService.allocateKubernetesCluster;
  model.getAllocations = hubApiService.getKubernetesClusterAllocations;
  model.getRobotTokens = hubApiService.getKubernetesClusterRobotTokens;
  model.getUserTokens = hubApiService.getKubernetesClusterUserTokens;

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
          $timeout(() => {
            fetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return fetcherPromise;
  }
};
