export const appConfig = ($mdIconProvider, $mdThemingProvider) => {
  'ngInject';

  $mdIconProvider
    .icon("menu", "./assets/svg/menu.svg", 24);

  $mdThemingProvider.theme('default')
    .primaryPalette('blue')
    .accentPalette('red');
};
