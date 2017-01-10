export const ShellComponent = {
  template: require('./shell.html'),
  controller: ShellController
};

function ShellController($mdSidenav) {
  'ngInject';

  const ctrl = this;

  ctrl.toggleMenu = toggleMenu;

  function toggleMenu() {
    $mdSidenav('left').toggle();
  }
}
