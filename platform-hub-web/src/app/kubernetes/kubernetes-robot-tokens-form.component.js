export const KubernetesRobotTokensFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-robot-tokens-form.html'),
  controller: KubernetesRobotTokensFormController
};

function KubernetesRobotTokensFormController($state, hubApiService, KubernetesClusters, logger, _) {
  'ngInject';

  const ctrl = this;

  const cluster = ctrl.transition && ctrl.transition.params().cluster;
  const tokenId = ctrl.transition && ctrl.transition.params().tokenId;

  ctrl.KubernetesClusters = KubernetesClusters;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.tokenData = null;
  ctrl.searchText = '';
  ctrl.user = null;

  ctrl.searchUsers = searchUsers;
  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.loading = true;

    KubernetesClusters
      .refresh()
      .then(setupToken)
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function setupToken() {
    ctrl.isNew = !tokenId;
    ctrl.tokenData = null;

    if (ctrl.isNew) {
      ctrl.tokenData = {
        cluster: {
          name: cluster
        }
      };
    } else {
      return hubApiService
        .getKubernetesRobotTokens(cluster)
        .then(tokens => {
          ctrl.tokenData = _.find(tokens, ['id', tokenId]);
          ctrl.user = ctrl.tokenData.user;
        });
    }
  }

  function searchUsers(query) {
    return hubApiService.searchUsers(query, true);
  }

  function createOrUpdate() {
    if (ctrl.kubernetesTokenForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      hubApiService
        .createKubernetesRobotToken(ctrl.user, ctrl.tokenData)
        .then(() => {
          logger.success('New kubernetes robot token created');
          $state.go('kubernetes.robot-tokens.list', {cluster: ctrl.tokenData.cluster.name});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      hubApiService
        .updateKubernetesRobotToken(tokenId, ctrl.user, ctrl.tokenData)
        .then(() => {
          logger.success('Kubernetes robot token updated');
          $state.go('kubernetes.robot-tokens.list', {cluster: ctrl.tokenData.cluster.name});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }
}
