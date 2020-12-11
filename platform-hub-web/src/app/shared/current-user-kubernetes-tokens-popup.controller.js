export const currentUserKubernetesTokensPopupController = function ($mdDialog, icons, Me, kubeConfigHelperPopupService, _) {
  'ngInject';

  const ctrl = this;

  ctrl.escalatedIcon = icons.escalateToken;

  ctrl.loading = true;
  ctrl.tokensByProject = {};
  ctrl.regenerateState = null;

  ctrl.close = $mdDialog.hide;
  ctrl.openKubeConfigHelperPopup = openKubeConfigHelperPopup;

  init();

  function init() {
    ctrl.loading = true;

    Me
      .getKubernetesTokens()
      .then(tokens => {
        ctrl.tokensByProject = _.groupBy(tokens, t => `Project: ${t.project.name} (${t.project.shortname})`);
        _.forEach(tokens, token => {
          if (token.kind === 'user') {
            ctrl.regenerateState = 'kubernetes.user-tokens.regenerate';
          }
        });
        _.map(tokens, t => {
          ctrl.tokenExpiry = new Date(t.expire_token_at).getTime();
          ctrl.dateNow = new Date().getTime();
          if (ctrl.tokenExpiry < ctrl.dateNow) {
            t.expiredToken = true;
          }
          return t;
        });
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function openKubeConfigHelperPopup(token, targetEvent) {
    return kubeConfigHelperPopupService.open(token, targetEvent);
  }
};
