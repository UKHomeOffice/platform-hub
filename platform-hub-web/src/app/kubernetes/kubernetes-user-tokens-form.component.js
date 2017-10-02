export const KubernetesUserTokensFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-user-tokens-form.html'),
  controller: KubernetesUserTokensFormController
};

function KubernetesUserTokensFormController($state, hubApiService, logger, _, KubernetesClusters) {
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
  ctrl.searchText = '';
  ctrl.user = null;

  ctrl.loadTokenData = loadTokenData;
  ctrl.searchUsers = searchUsers;
  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !cluster;
    ctrl.loading = true;

    // Kubernetes clusters are defined as follows:
    // [
    //   {id: 'cluster1', description: 'Cluster 1'},
    //   {id: 'cluster2', description: 'Cluster 2'},
    //   ...
    // ];
    KubernetesClusters
      .refresh()
      .then(() => {
        if (userId) {
          return loadUserAndToken();
        }
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
        return loadTokenData();
      });
  }

  function loadTokenData() {
    if (ctrl.user) {
      return hubApiService
        .getUserIdentities(ctrl.user.id)
        .then(identities => {
          const identity = _.find(identities, ['provider', 'kubernetes']);

          if (identity) {
            ctrl.tokenData = _.find(identity.kubernetes_tokens, ['cluster', cluster]);
            ctrl.assignedKubernetesClusters = _.map(identity.kubernetes_tokens, 'cluster');
          } else {
            ctrl.tokenData = {};
            ctrl.assignedKubernetesClusters = [];
          }
        });
    }
  }

  function searchUsers(query) {
    return hubApiService.searchUsers(query, true);
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
        $state.go('kubernetes.user-tokens.list', {userId: ctrl.user.id});
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
