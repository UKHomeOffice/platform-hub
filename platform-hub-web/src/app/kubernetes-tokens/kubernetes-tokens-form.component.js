export const KubernetesTokensFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-tokens-form.html'),
  controller: KubernetesTokensFormController
};

function KubernetesTokensFormController($state, hubApiService, logger, _, KubernetesClusters, FeatureFlags) {
  'ngInject';

  const ctrl = this;

  const userId = ctrl.transition && ctrl.transition.params().userId;
  const cluster = ctrl.transition && ctrl.transition.params().cluster;

  ctrl.KubernetesClusters = KubernetesClusters;
  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.tokenData = null;
  ctrl.assignedKubernetesClusters = null;
  ctrl.user = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !cluster;
    ctrl.loading = true;

    if (!FeatureFlags.isEnabled(FeatureFlags.keys.kubernetesTokens)) {
      $state.go('home'); // feature disabled
    }

    // Kubernetes clusters are defined as follows:
    // [
    //   {id: 'cluster1', description: 'Cluster 1'},
    //   {id: 'cluster2', description: 'Cluster 2'},
    //   ...
    // ];
    KubernetesClusters
      .refresh()
      .then(() => {
        return loadUserAndToken();
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function loadUserAndToken() {
    return hubApiService
      .getUser(userId)
      .then(user => {
        ctrl.user = user;
        fetchClusterToken();
      });
  }

  function fetchClusterToken() {
    const identity = _.find(ctrl.user.identities, 'provider', 'kubernetes');

    if (identity) {
      ctrl.tokenData = _.find(identity.kubernetes_tokens, t => {
        return t.cluster === cluster;
      });

      ctrl.assignedKubernetesClusters = _.map(identity.kubernetes_tokens, 'cluster');
    } else {
      ctrl.tokenData = {};
      ctrl.assignedKubernetesClusters = [];
    }
  }

  function createOrUpdate() {
    ctrl.saving = true;

    hubApiService
      .createOrUpdateKubernetesToken(ctrl.user, ctrl.tokenData)
      .then(t => {
        if (ctrl.isNew) {
          logger.success('New kubernetes token created for ' + t.cluster);
        } else {
          logger.success(t.cluster + ' kubernetes token updated');
        }
        $state.go('kubernetes-tokens.list', {userId: ctrl.user.id});
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
