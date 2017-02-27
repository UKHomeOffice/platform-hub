export const ShellComponent = {
  template: require('./shell.html'),
  controller: ShellController
};

function ShellController($scope, $mdSidenav, authService, roleCheckerService, events) {
  'ngInject';

  const ctrl = this;

  ctrl.isAdmin = false;

  ctrl.myAccountNavStates = [
    {
      title: 'Connected Identities',
      state: 'identities',
      icon: 'account_box'
    }
  ];

  ctrl.hubNavStates = [
    {
      title: 'Projects',
      state: 'projects.list',
      activeState: 'projects',
      icon: 'book'
    },
    {
      title: 'Help',
      state: 'help',
      icon: 'help'
    }
  ];

  ctrl.adminNavStates = [
    {
      title: 'Users',
      state: 'users',
      icon: 'perm_identity'
    }
  ];

  ctrl.toggleMenu = toggleMenu;
  ctrl.isAuthenticated = isAuthenticated;

  init();

  function init() {
    // Listen for changes to the Me profile data
    $scope.$on(events.api.me.updated, loadAdminStatus);

    if (isAuthenticated()) {
      loadAdminStatus();
    }
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
