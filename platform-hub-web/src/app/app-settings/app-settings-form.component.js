export const AppSettingsFormComponent = {
  template: require('./app-settings-form.html'),
  controller: AppSettingsFormController
};

function AppSettingsFormController($state, AppSettings, PlatformThemesList, _) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.settings = {};
  ctrl.visiblePlatformThemes = [];
  ctrl.hiddenPlatformThemes = [];

  ctrl.update = update;

  init();

  function init() {
    AppSettings
      .refresh()
      .then(settings => {
        // Make sure to store a copy as we may be mutating this!
        angular.copy(settings, ctrl.settings);

        return refreshPlatformThemesLists()
          .then(() => {
            // Only stop loading if it's a successful fetch
            // (i.e. the following doesn't go into a .finally handler)
            ctrl.loading = false;
          });
      });
  }

  function update() {
    ctrl.saving = true;

    ctrl.settings.visiblePlatformThemes = _.map(ctrl.visiblePlatformThemes, 'id');

    AppSettings
      .update(ctrl.settings)
      .then(() => {
        $state.go('home');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function refreshPlatformThemesLists() {
    return PlatformThemesList
      .refresh()
      .then(() => {
        // Make sure to store copies as we may be mutating these!
        angular.copy(PlatformThemesList.visible, ctrl.visiblePlatformThemes);
        angular.copy(PlatformThemesList.hidden, ctrl.hiddenPlatformThemes);
      });
  }
}
