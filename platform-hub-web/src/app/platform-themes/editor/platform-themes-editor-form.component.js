export const PlatformThemesEditorFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./platform-themes-editor-form.html'),
  controller: PlatformThemesEditorFormController
};

function PlatformThemesEditorFormController($state, $mdColorPalette, hubApiService, PlatformThemesResourceKinds, UserScopes, logger, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  // Colours from the material design spec
  ctrl.colours = Object.keys($mdColorPalette);

  ctrl.resourceKinds = PlatformThemesResourceKinds.all;
  ctrl.userScopes = UserScopes.all;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.theme = null;

  ctrl.createOrUpdate = createOrUpdate;
  ctrl.addResource = addResource;
  ctrl.removeResource = removeResource;
  ctrl.handleResourceKindChange = handleResourceKindChange;
  ctrl.moveResourceDown = moveResourceDown;
  ctrl.moveResourceUp = moveResourceUp;

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
      colour: _.sample(ctrl.colours),
      resources: []
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

  function addResource() {
    if (!ctrl.theme.resources) {
      ctrl.theme.resources = [];
    }
    ctrl.theme.resources.push({
      visible: true
    });
  }

  function removeResource(ix) {
    if (!_.isEmpty(ctrl.theme.resources)) {
      ctrl.theme.resources.splice(ix, 1);
    }
  }

  function handleResourceKindChange(ix) {
    const resource = ctrl.theme.resources[ix];
    if (resource) {
      ctrl.resourceKinds.forEach(k => {
        delete resource[k.kind];
      });
      resource[resource.kind] = {};
    }
  }

  function moveResourceDown(ix) {
    const resources = ctrl.theme.resources;
    const resource1 = resources[ix];
    const resource2 = resources[ix + 1];
    resources.splice(ix, 2, resource2, resource1);
  }

  function moveResourceUp(ix) {
    const resources = ctrl.theme.resources;
    const resource1 = resources[ix - 1];
    const resource2 = resources[ix];
    resources.splice(ix - 1, 2, resource2, resource1);
  }
}
