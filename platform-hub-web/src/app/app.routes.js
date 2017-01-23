import {AppHome} from './home/home.module';
import {IdentitiesManager} from './identities/identities.module';

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
    })
    .state('identities', {
      url: '/identities',
      component: IdentitiesManager,
      data: {
        authenticate: true
      }
    });
};
