import {AppHome} from './home/home.module';

export const appRoutes = function ($stateProvider, $urlRouterProvider, $locationProvider) {
  'ngInject';

  $locationProvider.html5Mode(true);
  $urlRouterProvider.otherwise('/');

  $stateProvider
    .state('home', {
      url: '/',
      component: AppHome,
      data: {
        authenticate: false
      }
    });
};
