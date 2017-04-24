export const HomeComponent = {
  template: require('./home.html'),
  controller: HomeController
};

function HomeController($scope, $sce, events, authService, onboardingTrigger, AppSettings, PlatformThemes) {
  'ngInject';

  const ctrl = this;

  ctrl.AppSettings = AppSettings;
  ctrl.PlatformThemes = PlatformThemes;

  ctrl.platformOverviewText = '';

  ctrl.login = login;
  ctrl.isAuthenticated = isAuthenticated;

  init();

  function init() {
    // Listen for changes to the Me profile data
    $scope.$on(events.auth.updated, () => {
      if (isAuthenticated()) {
        refresh();
      }
    });

    if (isAuthenticated()) {
      refresh();
    }

    AppSettings
      .refresh()
      .then(() => {
        ctrl.platformOverviewText = $sce.trustAsHtml(AppSettings.getPlatformOverviewText());
      });
  }

  function refresh() {
    PlatformThemes.refresh();
  }

  function isAuthenticated() {
    return authService.isAuthenticated();
  }

  function login() {
    authService
      .authenticate()
      .then(onboardingTrigger);
  }
}
