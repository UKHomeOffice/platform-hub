export const FeatureFlagsFormComponent = {
  template: require('./feature-flags-form.html'),
  controller: FeatureFlagsFormController
};

function FeatureFlagsFormController(featureFlagKeys, FeatureFlags) {
  'ngInject';

  const ctrl = this;

  ctrl.featureFlagKeys = featureFlagKeys;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.flags = {};

  ctrl.update = update;

  init();

  function init() {
    reload();
  }

  function reload() {
    ctrl.loading = true;

    FeatureFlags
      .refresh()
      .then(flags => {
        angular.copy(flags, ctrl.flags);
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function update(flag, state) {
    ctrl.saving = true;

    FeatureFlags
      .update(flag, state)
      .then(reload)
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
