export const KubernetesTokenValueComponent = {
  bindings: {
    item: '<'
  },
  template: require('./kubernetes-token-value.html'),
  controller: KubernetesTokenValueController
};

function KubernetesTokenValueController(icons, _) {
  'ngInject';

  const ctrl = this;

  ctrl.copyIcon = icons.copy;

  _.map(ctrl.item, token => {
    ctrl.tokenExpiry = new Date(ctrl.item.expire_token_at).getTime();
    ctrl.dateNow = new Date().getTime();
    if (ctrl.tokenExpiry < ctrl.dateNow) {
      ctrl.item.expiredToken = true;
    }
    return token;
  });
}
