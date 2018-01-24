/* eslint camelcase: 0 */

export const KubernetesNamespaces = function (hubApiService) {
  'ngInject';

  const model = {};

  model.listByService = listByService;
  model.listByCluster = listByCluster;
  model.get = hubApiService.getKubernetesNamespace;
  model.create = hubApiService.createKubernetesNamespace;
  model.update = hubApiService.updateKubernetesNamespace;
  model.delete = hubApiService.deleteKubernetesNamespace;

  return model;

  function listByService(serviceId, page = 1) {
    return hubApiService.getKubernetesNamespaces({service_id: serviceId}, page);
  }

  function listByCluster(clusterName, page = 1) {
    return hubApiService.getKubernetesNamespaces({cluster_name: clusterName}, page);
  }
};
