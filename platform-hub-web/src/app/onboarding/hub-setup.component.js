/* eslint camelcase: 0 */

export const HubSetupComponent = {
  template: require('./hub-setup.html'),
  controller: HubSetupController
};

function HubSetupController(Me) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.data = {};

  ctrl.update = update;

  init();

  function init() {
    ctrl.loading = true;

    Me
      .refresh()
      .then(processMeData)
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function update() {
    ctrl.saving = true;

    Me
      .completeHubOnboarding(ctrl.data)
      .then(processMeData)
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function processMeData(meData) {
    ctrl.data = {
      is_managerial: meData.is_managerial,
      is_technical: meData.is_technical
    };
  }
}
