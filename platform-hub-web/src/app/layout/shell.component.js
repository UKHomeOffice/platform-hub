export const ShellComponent = {
  template: require('./shell.html'),
  controller: ShellController
};

function ShellController($mdSidenav) {
  'ngInject';

  const ctrl = this;

  ctrl.navStates = [
    {
      title: 'Connected Identities',
      state: 'identities',
      icon: 'account_box'
    }
  ];

  ctrl.toggleMenu = toggleMenu;

  function toggleMenu() {
    $mdSidenav('left').toggle();
  }
}
