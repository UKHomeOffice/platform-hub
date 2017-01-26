import {AppHome} from './home/home.module';
import {IdentitiesManager} from './identities/identities.module';
import {
  ProjectsForm,
  ProjectsDetail,
  ProjectsList
} from './projects/projects.module';
import {UsersList} from './users/users.module';

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
    })
    .state('projects', {
      abstract: true,
      url: '/projects',
      template: '<ui-view/>'
    })
      .state('projects.list', {
        url: '/',
        component: ProjectsList,
        data: {
          authenticate: true
        }
      })
      .state('projects.detail', {
        url: '/:id',
        component: ProjectsDetail,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true
        }
      })
      .state('projects.new', {
        url: '/new',
        component: ProjectsForm,
        data: {
          authenticate: true,
          rolePermitted: 'admin'
        }
      })
      .state('projects.edit', {
        url: '/:id/edit',
        component: ProjectsForm,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolePermitted: 'admin'
        }
      })
    .state('users', {
      url: '/users',
      component: UsersList,
      data: {
        authenticate: true,
        rolePermitted: 'admin'
      }
    });
};
