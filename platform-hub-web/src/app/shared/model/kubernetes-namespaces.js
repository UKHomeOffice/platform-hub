/* eslint camelcase: 0 */

export const KubernetesNamespaces = function (hubApiService) {
  'ngInject';

  const model = {};

  model.getAllByService = getAllByService;
  model.getAllByCluster = getAllByCluster;
  model.get = hubApiService.getKubernetesNamespace;
  model.create = hubApiService.createKubernetesNamespace;
  model.update = hubApiService.updateKubernetesNamespace;
  model.delete = hubApiService.deleteKubernetesNamespace;

  return model;

  function getAllByService(serviceId) {
    return hubApiService.getKubernetesNamespaces({service_id: serviceId});
  }

  function getAllByCluster(clusterName) {
    return hubApiService.getKubernetesNamespaces({cluster_name: clusterName});
  }
};
