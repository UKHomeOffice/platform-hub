import angular from 'angular';

export const KubernetesGroups = function ($window, hubApiService, apiBackoffTimeMs, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.kinds = [
    'clusterwide',
    'namespace'
  ];

  model.targets = [
    'user',
    'robot'
  ];

  model.all = [];

  model.refresh = refresh;
  model.get = hubApiService.getKubernetesGroup;
  model.create = hubApiService.createKubernetesGroup;
  model.update = hubApiService.updateKubernetesGroup;
  model.delete = hubApiService.deleteKubernetesGroup;
  model.allocateToProject = allocateToProject;
  model.allocateToService = allocateToService;

  return model;

  function refresh(force) {
    if (force || _.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getKubernetesGroups()
        .then(groups => {
          angular.copy(groups, model.all);
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

  function allocateToProject(groupId, projectId) {
    return hubApiService.allocateKubernetesGroup(groupId, projectId);
  }

  function allocateToService(groupId, projectId, serviceId) {
    return hubApiService.allocateKubernetesGroup(groupId, projectId, serviceId);
  }
};