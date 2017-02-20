export const appConfig = function ($mdIconProvider, $mdThemingProvider, $httpProvider, jwtOptionsProvider) {
  'ngInject';

  $mdIconProvider
    .icon('menu', './assets/svg/menu.svg', 24);

  $mdThemingProvider.theme('default')
    .primaryPalette('blue')
    .accentPalette('red');

  // Set up authenticated API access
  jwtOptionsProvider.config({               // eslint-disable-line
    tokenGetter: authService => {
      'ngInject';

      return authService.getToken();
    }
  });
  $httpProvider.interceptors.push('jwtInterceptor');
};
