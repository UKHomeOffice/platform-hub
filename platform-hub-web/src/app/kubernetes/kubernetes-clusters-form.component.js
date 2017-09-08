export const KubernetesClustersFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-clusters-form.html'),
  controller: KubernetesClustersFormController
};

function KubernetesClustersFormController($state, KubernetesClusters, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.cluster = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.cluster = {};
      ctrl.loading = false;
    } else {
      loadCluster();
    }
  }

  function loadCluster() {
    ctrl.loading = true;
    ctrl.cluster = {};

    KubernetesClusters
      .get(id)
      .then(cluster => {
        // Make sure to store a copy as we may be mutating this!
        angular.copy(cluster, ctrl.cluster);
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.clusterForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    KubernetesClusters
      .createOrUpdate(ctrl.cluster.id, ctrl.cluster)
      .then(() => {
        logger.success('Cluster created or updated successfully');
        $state.go('kubernetes.clusters.list');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
