export const KubernetesTokenCardComponent = {
  bindings: {
    token: '<',
    showActions: '<',
    busy: '=',
    afterUpdate: '&',
    fromProject: '<',
    fromService: '<'  // Must be provided if `fromProject` is provided
  },
  template: require('./kubernetes-token-card.html'),
  controller: KubernetesTokenCardController
};

function KubernetesTokenCardController($mdDialog, KubernetesTokens, _, $state, Projects, featureFlagKeys, FeatureFlags, kubernetesTokenEscalatePrivilegePopupService, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.featureFlagKeys = featureFlagKeys;
  ctrl.FeatureFlags = FeatureFlags;

  ctrl.editState = null;
  ctrl.editStateParams = null;

  ctrl.regenerateState = null;
  ctrl.regenerateStateParams = null;

  ctrl.escalatePrivilege = escalatePrivilege;
  ctrl.deleteToken = deleteToken;

  init();

  function init() {
    if (ctrl.token.kind === 'robot') {
      ctrl.editState = 'kubernetes.robot-tokens.edit';
      ctrl.editStateParams = {
        cluster: ctrl.token.cluster.name,
        tokenId: ctrl.token.id
      };
      ctrl.regenerateState = 'kubernetes.robot-tokens.regenerate';
      ctrl.regenerateStateParams = {
        cluster: ctrl.token.cluster.name,
        tokenId: ctrl.token.id
      };

      if (ctrl.fromProject) {
        ctrl.editStateParams.fromProject = ctrl.fromProject;
        ctrl.editStateParams.fromService = ctrl.fromService;
        ctrl.regenerateStateParams.fromProject = ctrl.fromProject;
        ctrl.regenerateStateParams.fromService = ctrl.fromService;
      }
    } else if (ctrl.token.kind === 'user') {
      ctrl.editState = 'kubernetes.user-tokens.edit';
      ctrl.editStateParams = {
        userId: ctrl.token.user.id,
        tokenId: ctrl.token.id
      };
      ctrl.regenerateState = 'kubernetes.user-tokens.regenerate';
      ctrl.regenerateStateParams = {
        userId: ctrl.token.user.id,
        tokenId: ctrl.token.id
      };

      if (ctrl.fromProject) {
        ctrl.editStateParams.fromProject = ctrl.fromProject;
        ctrl.regenerateStateParams.fromProject = ctrl.fromProject;
      }
    }
  }

  function escalatePrivilege(targetEvent) {
    return kubernetesTokenEscalatePrivilegePopupService.open(
      ctrl.token,
      targetEvent
    ).then(() => {
      if (ctrl.afterUpdate) {
        return ctrl.afterUpdate();
      }
    });
  }

  function deleteToken(targetEvent) {
    const confirm = $mdDialog.confirm()
    .title(`Are you sure?`)
    .textContent(`This will delete the selected token permanently.`)
    .ariaLabel('Confirm token deletion')
    .targetEvent(targetEvent)
    .ok('Do it')
    .cancel('Cancel');

    $mdDialog
    .show(confirm)
    .then(() => {
      ctrl.busy = true;

      let promise = null;

      if (ctrl.fromProject) {
        if (ctrl.token.kind === 'robot') {
          promise = Projects.deleteServiceKubernetesRobotToken(ctrl.fromProject, ctrl.fromService, ctrl.token.id);
        } else if (ctrl.token.kind === 'user') {
          promise = Projects.deleteKubernetesUserToken(ctrl.fromProject, ctrl.token.id);
        }
      } else {
        promise = KubernetesTokens.deleteToken(ctrl.token.id);
      }

      return promise
      .then(() => {
        logger.success('Token deleted');

        if (ctrl.afterUpdate) {
          return ctrl.afterUpdate();
        }
      })
      .finally(() => {
        ctrl.busy = false;
      });
    });
  }
}
