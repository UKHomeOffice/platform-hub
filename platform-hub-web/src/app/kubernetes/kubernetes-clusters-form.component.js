export const KubernetesClustersFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-clusters-form.html'),
  controller: KubernetesClustersFormController
};

function KubernetesClustersFormController($state, KubernetesClusters, chipsHelpers, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.awsAccountIdRegex = '^[0-9]{12}$';

  ctrl.separatorKeys = chipsHelpers.separatorKeys;
  ctrl.separatorKeysHelpText = chipsHelpers.separatorKeysHelpText;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.cluster = null;

  ctrl.createOrUpdate = createOrUpdate;
  ctrl.processAliasesChip = processAliasesChip;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.cluster = {
        aliases: []
      };
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

    if (ctrl.isNew) {
      KubernetesClusters
        .create(ctrl.cluster)
        .then(() => {
          logger.success('New cluster created');
          $state.go('kubernetes.clusters.list');
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      KubernetesClusters
        .update(ctrl.cluster.id, ctrl.cluster)
        .then(() => {
          logger.success('Cluster updated');
          $state.go('kubernetes.clusters.list');
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }

  function processAliasesChip(chip) {
    if (chipsHelpers.hasInvalidChars(chip)) {
      logger.warning(`Cannot add alias. ${chipsHelpers.hasInvalidCharsErrorMessage}`);
      return null;
    }
  }
}
