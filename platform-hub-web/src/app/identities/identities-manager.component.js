export const IdentitiesManagerComponent = {
  template: require('./identities-manager.html'),
  controller: IdentitiesManagerController
};

function IdentitiesManagerController() {
  'ngInject';

  const ctrl = this;

  ctrl.busy = true;
}
