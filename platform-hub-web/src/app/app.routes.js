import {AppSettingsForm} from './app-settings/app-settings.module';
import {
  Faq,
  SupportRequestsForm,
  SupportRequestsOverview,
  SupportRequestTemplatesDetail,
  SupportRequestTemplatesForm,
  SupportRequestTemplatesList
} from './help/help.module';
import {AppHome} from './home/home.module';
import {IdentitiesManager} from './identities/identities.module';
import {HubSetup} from './onboarding/onboarding.module';
import {
  PlatformThemesEditorForm,
  PlatformThemesEditorList,
  PlatformThemesPage
} from './platform-themes/platform-themes.module';
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
    .state('onboarding', {
      abstract: true,
      url: '/onboarding',
      template: '<ui-view></ui-view>'
    })
      .state('onboarding.hub-setup', {
        url: '/hub-setup',
        component: HubSetup,
        data: {
          authenticate: true
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
      template: '<ui-view></ui-view>'
    })
      .state('projects.list', {
        url: '/list',
        component: ProjectsList,
        data: {
          authenticate: true
        }
      })
      .state('projects.detail', {
        url: '/detail/:id',
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
        url: '/edit/:id',
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
    })
    .state('help', {
      abstract: true,
      url: '/help',
      template: '<ui-view></ui-view>'
    })
      .state('help.faq', {
        url: '/faq',
        component: Faq,
        data: {
          authenticate: true
        }
      })
      .state('help.support', {
        abstract: true,
        url: '/support',
        template: '<ui-view></ui-view>'
      })
        .state('help.support.requests', {
          abstract: true,
          url: '/requests',
          template: '<ui-view></ui-view>'
        })
          .state('help.support.requests.overview', {
            url: '/overview',
            component: SupportRequestsOverview,
            data: {
              authenticate: true
            }
          })
          .state('help.support.requests.new', {
            url: '/new/:id',
            component: SupportRequestsForm,
            resolve: {
              transition: '$transition$'
            },
            data: {
              authenticate: true
            }
          })
        .state('help.support.request-templates', {
          abstract: true,
          url: '/request-templates',
          template: '<ui-view></ui-view>'
        })
          .state('help.support.request-templates.list', {
            url: '/list',
            component: SupportRequestTemplatesList,
            data: {
              authenticate: true,
              rolePermitted: 'admin'
            }
          })
          .state('help.support.request-templates.detail', {
            url: '/detail/:id',
            component: SupportRequestTemplatesDetail,
            resolve: {
              transition: '$transition$'
            },
            data: {
              authenticate: true,
              rolePermitted: 'admin'
            }
          })
          .state('help.support.request-templates.new', {
            url: '/new',
            component: SupportRequestTemplatesForm,
            data: {
              authenticate: true,
              rolePermitted: 'admin'
            }
          })
          .state('help.support.request-templates.edit', {
            url: '/edit/:id',
            component: SupportRequestTemplatesForm,
            resolve: {
              transition: '$transition$'
            },
            data: {
              authenticate: true,
              rolePermitted: 'admin'
            }
          })
    .state('platform-themes', {
      abstract: true,
      url: '/platform-themes',
      template: '<ui-view></ui-view>'
    })
      .state('platform-themes.editor', {
        abstract: true,
        url: '/editor',
        template: '<ui-view></ui-view>'
      })
        .state('platform-themes.editor.list', {
          url: '/list',
          component: PlatformThemesEditorList,
          data: {
            authenticate: true,
            rolePermitted: 'admin'
          }
        })
        .state('platform-themes.editor.new', {
          url: '/new',
          component: PlatformThemesEditorForm,
          data: {
            authenticate: true,
            rolePermitted: 'admin'
          }
        })
        .state('platform-themes.editor.edit', {
          url: '/edit/:id',
          component: PlatformThemesEditorForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            rolePermitted: 'admin'
          }
        })
      .state('platform-themes.page', {
        url: '/page/:id',
        component: PlatformThemesPage,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true
        }
      })
    .state('app-settings', {
      url: '/app-settings/edit',
      component: AppSettingsForm,
      data: {
        authenticate: true,
        rolePermitted: 'admin'
      }
    });
};
