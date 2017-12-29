export const KubernetesIdentityTokensPopupController = function ($mdDialog, icons, kubeConfigHelperPopupService, identity, _) {
  'ngInject';

  const ctrl = this;

  ctrl.escalatedIcon = icons.escalateToken;
  ctrl.identity = identity;

  ctrl.tokensByProject = {};

  ctrl.close = $mdDialog.hide;
  ctrl.openKubeConfigHelperPopup = openKubeConfigHelperPopup;

  init();

  function init() {
    if (!_.isEmpty(identity.kubernetes_tokens)) {
      ctrl.tokensByProject = _.groupBy(identity.kubernetes_tokens, t => `Project: ${t.project.name} (${t.project.shortname})`);
    }
  }

  function openKubeConfigHelperPopup(kubeId, token, targetEvent) {
    return kubeConfigHelperPopupService.open(kubeId, token, targetEvent);
  }
};
