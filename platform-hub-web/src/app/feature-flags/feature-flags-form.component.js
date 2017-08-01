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
    ctrl.loading = true;

    FeatureFlags
      .refresh()
      .then(copyFlagsLocally)
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function update(flag, state) {
    ctrl.saving = true;

    FeatureFlags
      .update(flag, state)
      .then(copyFlagsLocally)
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function copyFlagsLocally() {
    angular.copy(FeatureFlags.data, ctrl.flags);
  }
}
