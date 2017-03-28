export const PlatformThemesPageComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./platform-themes-page.html'),
  controller: PlatformThemesPageController
};

function PlatformThemesPageController(hubApiService, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.theme = null;

  init();

  function init() {
    loadTheme();
  }

  function loadTheme() {
    if (_.isNull(id) || _.isEmpty(id)) {
      ctrl.loading = false;
      return;
    }

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
}
