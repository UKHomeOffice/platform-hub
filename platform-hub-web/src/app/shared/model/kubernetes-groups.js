export const KubernetesGroups = function (hubApiService, _) {
  'ngInject';

  const model = {};

  model.kinds = [
    'clusterwide',
    'namespace'
  ];

  model.targets = [
    'user',
    'robot'
  ];

  model.list = hubApiService.getKubernetesGroups;
  model.get = hubApiService.getKubernetesGroup;
  model.create = hubApiService.createKubernetesGroup;
  model.update = hubApiService.updateKubernetesGroup;
  model.delete = hubApiService.deleteKubernetesGroup;
  model.allocateToProject = allocateToProject;
  model.allocateToService = allocateToService;
  model.getAllocations = hubApiService.getKubernetesGroupAllocations;
  model.getTokens = hubApiService.getKubernetesGroupTokens;

  model.filterGroupsForCluster = filterGroupsForCluster;

  return model;

  function allocateToProject(groupId, projectId) {
    return hubApiService.allocateKubernetesGroup(groupId, projectId);
  }

  function allocateToService(groupId, projectId, serviceId) {
    return hubApiService.allocateKubernetesGroup(groupId, projectId, serviceId);
  }

  function filterGroupsForCluster(groups, clusterName) {
    return _.filter(groups, g => {
      return (
        !g.restricted_to_clusters ||
        _.isEmpty(g.restricted_to_clusters) ||
        g.restricted_to_clusters.includes(clusterName)
      );
    });
  }
};
