export const PlatformThemesEditorListComponent = {
  template: require('./platform-themes-editor-list.html'),
  controller: PlatformThemesEditorListController
};

function PlatformThemesEditorListController($mdDialog, PlatformThemes, icons, hubApiService, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.PlatformThemes = PlatformThemes;
  ctrl.platformThemeIcon = icons.platformThemes;

  ctrl.loading = true;

  ctrl.deleteTheme = deleteTheme;

  init();

  function init() {
    refreshThemes();
  }

  function refreshThemes() {
    ctrl.loading = true;

    PlatformThemes
      .refresh()
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function deleteTheme(theme, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the platform theme permanently from the hub.')
      .ariaLabel('Confirm deletion of platform theme')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .deletePlatformTheme(theme.id)
          .then(() => {
            logger.success('Platform theme deleted');
            refreshThemes();
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }
}
