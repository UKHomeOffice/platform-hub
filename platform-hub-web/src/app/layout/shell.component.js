export const ShellComponent = {
  template: require('./shell.html'),
  controller: ShellController
};

function ShellController($scope, $mdSidenav, authService, roleCheckerService, events, icons, AppSettings, PlatformThemesList) {
  'ngInject';

  const ctrl = this;

  ctrl.AppSettings = AppSettings;
  ctrl.PlatformThemesList = PlatformThemesList;
  ctrl.platformThemeIcon = icons.platformThemes;

  ctrl.isAdmin = false;

  ctrl.myAccountNavStates = [
    {
      title: 'Connected Identities',
      state: 'identities',
      icon: icons.identities
    }
  ];

  ctrl.orgNavStates = [
    {
      title: 'Projects',
      state: 'projects.list',
      activeState: 'projects',
      icon: icons.projects
    }
  ];

  ctrl.helpNavStates = [
    {
      title: 'FAQ',
      state: 'help.faq',
      icon: icons.faq
    },
    {
      title: 'Support Requests',
      state: 'help.support.requests.overview',
      activeState: 'help.support.requests',
      icon: icons.supportRequests
    }
  ];

  ctrl.adminNavStates = [
    {
      title: 'Users',
      state: 'users',
      icon: icons.users
    },
    {
      title: 'App Settings',
      state: 'app-settings',
      icon: icons.appSettings
    },
    {
      title: 'Platform Themes',
      state: 'platform-themes.editor.list',
      activeState: 'platform-themes.editor',
      icon: ctrl.platformThemeIcon
    },
    {
      title: 'Support Request Templates',
      state: 'help.support.request-templates.list',
      activeState: 'help.support.request-templates',
      icon: icons.supportRequests
    }
  ];

  ctrl.toggleMenu = toggleMenu;
  ctrl.isAuthenticated = isAuthenticated;

  init();

  function init() {
    $scope.$on(events.auth.updated, () => {
      if (isAuthenticated()) {
        refresh();
      } else {
        ctrl.isAdmin = false;
      }
    });

    if (isAuthenticated()) {
      refresh();
    }
  }

  function refresh() {
    loadAdminStatus();
    PlatformThemesList.refresh();
  }

  function loadAdminStatus() {
    roleCheckerService
      .hasHubRole('admin')
      .then(hasRole => {
        ctrl.isAdmin = hasRole;
      });
  }

  function toggleMenu() {
    $mdSidenav('left').toggle();
  }

  function isAuthenticated() {
    return authService.isAuthenticated();
  }
}
