export const KubernetesTokenValueComponent = {
  bindings: {
    item: '<'
  },
  template: require('./kubernetes-token-value.html'),
  controller: KubernetesTokenValueController
};

function KubernetesTokenValueController(icons) {
  'ngInject';

  const ctrl = this;

  ctrl.copyIcon = icons.copy;
}
