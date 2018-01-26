export const KubernetesClustersDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-clusters-detail.html'),
  controller: KubernetesClustersDetailController
};

function KubernetesClustersDetailController(KubernetesClusters, projectServiceSelectorPopupService, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.cluster = null;
  ctrl.allocations = [];
  ctrl.loadingAllocations = false;
  ctrl.kubernetesRobotTokens = [];
  ctrl.processingKubernetesRobotTokens = false;
  ctrl.kubernetesUserTokens = [];
  ctrl.processingKubernetesUserTokens = false;

  ctrl.allocate = allocate;
  ctrl.loadAllocations = loadAllocations;
  ctrl.loadKubernetesRobotTokens = loadKubernetesRobotTokens;
  ctrl.loadKubernetesUserTokens = loadKubernetesUserTokens;

  init();

  function init() {
    loadCluster();
  }

  function loadCluster() {
    ctrl.loading = true;
    ctrl.cluster = null;

    KubernetesClusters
      .get(id)
      .then(cluster => {
        ctrl.cluster = cluster;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function allocate(targetEvent) {
    return projectServiceSelectorPopupService
      .openForProjectOnly(targetEvent)
      .then(result => {
        return KubernetesClusters.allocate(ctrl.cluster.id, result.project.id);
      })
      .then(() => {
        logger.success('Successfully allocated this cluster to a project');
        loadAllocations();
      });
  }

  function loadAllocations() {
    ctrl.loadingAllocations = true;

    return KubernetesClusters
      .getAllocations(ctrl.cluster.id)
      .then(allocations => {
        angular.copy(allocations, ctrl.allocations);
      })
      .finally(() => {
        ctrl.loadingAllocations = false;
      });
  }

  function loadKubernetesRobotTokens(page = 1) {
    ctrl.processingKubernetesRobotTokens = true;

    return KubernetesClusters
      .getRobotTokens(ctrl.cluster.id, page)
      .then(tokens => {
        ctrl.kubernetesRobotTokens = tokens;
      })
      .finally(() => {
        ctrl.processingKubernetesRobotTokens = false;
      });
  }

  function loadKubernetesUserTokens(page = 1) {
    ctrl.processingKubernetesUserTokens = true;

    return KubernetesClusters
      .getUserTokens(ctrl.cluster.id, page)
      .then(tokens => {
        ctrl.kubernetesUserTokens = tokens;
      })
      .finally(() => {
        ctrl.processingKubernetesUserTokens = false;
      });
  }
}
