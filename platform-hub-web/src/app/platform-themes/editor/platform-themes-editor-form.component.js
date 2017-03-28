export const PlatformThemesEditorFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./platform-themes-editor-form.html'),
  controller: PlatformThemesEditorFormController
};

function PlatformThemesEditorFormController($state, $mdColorPalette, hubApiService, logger, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  // Colours from the material design spec
  ctrl.colours = Object.keys($mdColorPalette);

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.theme = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.theme = initEmptyTheme();
      ctrl.loading = false;
    } else {
      loadTheme();
    }
  }

  function initEmptyTheme() {
    return {
      colour: _.sample(ctrl.colours)
    };
  }

  function loadTheme() {
    ctrl.loading = true;
    ctrl.theme = null;

    hubApiService
      .getPlatformTheme(id)
      .then(theme => {
        ctrl.theme = theme;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.themeForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    const errors = validate(ctrl.theme);
    if (errors.length > 0) {
      logger.error(errors.join('<br />'));
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      hubApiService
        .createPlatformTheme(ctrl.theme)
        .then(() => {
          logger.success('Platform theme created');
          $state.go('platform-themes.editor.list');
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      hubApiService
        .updatePlatformTheme(ctrl.theme.id, ctrl.theme)
        .then(() => {
          logger.success('Platform theme updated');
          $state.go('platform-themes.editor.list');
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }

  function validate() {
    return [];
  }
}
