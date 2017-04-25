export const AppSettingsFormComponent = {
  template: require('./app-settings-form.html'),
  controller: AppSettingsFormController
};

function AppSettingsFormController($state, AppSettings, PlatformThemes, _) {
  'ngInject';

  const ctrl = this;

  // See https://github.com/yabwe/medium-editor#mediumeditor-options
  ctrl.editorOptions = {
    toolbar: {
      buttons: ['bold', 'italic', 'underline', 'anchor', 'image', 'h2', 'h3', 'h4', 'orderedlist', 'unorderedlist', 'indent', 'outdent', 'justifyLeft', 'justifyCenter', 'justifyRight', 'justifyFull', 'subscript', 'superscript', 'removeFormat']
    },
    targetBlank: true,
    imageDragging: false
  };

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

        return refreshPlatformThemes()
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

  function refreshPlatformThemes() {
    return PlatformThemes
      .refresh()
      .then(() => {
        // Make sure to store copies as we may be mutating these!
        angular.copy(PlatformThemes.visible, ctrl.visiblePlatformThemes);
        angular.copy(PlatformThemes.hidden, ctrl.hiddenPlatformThemes);
      });
  }
}
