export const currentUserKubernetesTokensPopupController = function ($mdDialog, icons, Me, kubeConfigHelperPopupService, _) {
  'ngInject';

  const ctrl = this;

  ctrl.escalatedIcon = icons.escalateToken;

  ctrl.loading = true;
  ctrl.tokensByProject = {};

  ctrl.close = $mdDialog.hide;
  ctrl.openKubeConfigHelperPopup = openKubeConfigHelperPopup;

  init();

  function init() {
    ctrl.loading = true;

    Me
      .getKubernetesTokens()
      .then(tokens => {
        ctrl.tokensByProject = _.groupBy(tokens, t => `Project: ${t.project.name} (${t.project.shortname})`);
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function openKubeConfigHelperPopup(token, targetEvent) {
    return kubeConfigHelperPopupService.open(token, targetEvent);
  }
};
