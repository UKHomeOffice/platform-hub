import {AppHome} from './home/home.module';

export const appRoutes = ($stateProvider, $urlRouterProvider, $locationProvider) => {
  'ngInject';

  $locationProvider.html5Mode(true);
  $urlRouterProvider.otherwise('/');

  $stateProvider
    .state('home', {
      url: '/',
      component: AppHome
    });
};
