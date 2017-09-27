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
  const name = ctrl.transition && ctrl.transition.params().name;

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
    ctrl.isNew = !name;
    ctrl.tokenData = null;

    if (ctrl.isNew) {
      ctrl.tokenData = {
        cluster
      };
    } else {
      return hubApiService
        .getKubernetesRobotTokens(cluster)
        .then(tokens => {
          ctrl.tokenData = _.find(tokens, ['name', name]);
          ctrl.user = ctrl.tokenData.user;
        });
    }
  }

  function searchUsers(query) {
    return hubApiService.searchUsers(query, true);
  }

  function createOrUpdate() {
    ctrl.saving = true;

    hubApiService
      .createOrUpdateKubernetesRobotToken(ctrl.tokenData.cluster, ctrl.tokenData.name, ctrl.tokenData.groups, ctrl.tokenData.description, ctrl.user && ctrl.user.id)
      .then(() => {
        logger.success('Token successfully created or updated');
        $state.go('kubernetes.robot-tokens.list', {cluster: ctrl.tokenData.cluster});
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
