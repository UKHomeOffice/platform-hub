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
  ctrl.loadingAllocations = [];

  ctrl.allocate = allocate;
  ctrl.loadAllocations = loadAllocations;

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
}
