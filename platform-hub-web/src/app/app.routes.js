import {
  AnnouncementsEditorForm,
  AnnouncementsEditorList,
  GlobalAnnouncements
} from './announcements/announcements.module';
import {AppSettingsForm} from './app-settings/app-settings.module';
import {
  ContactListsForm,
  ContactListsList
} from './contact-lists/contact-lists.module';
import {
  Faq,
  SupportRequestsForm,
  SupportRequestsOverview,
  SupportRequestTemplatesDetail,
  SupportRequestTemplatesForm,
  SupportRequestTemplatesList
} from './help/help.module';
import {
  AppHome,
  HomePreload
} from './home/home.module';
import {IdentitiesManager} from './identities/identities.module';
import {
  HubSetup,
  ServicesOnboarding
} from './onboarding/onboarding.module';
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
import {TermsOfService} from './terms-of-service/terms-of-service.module';
import {
  KubernetesTokensList,
  KubernetesTokensForm
} from './kubernetes-tokens/kubernetes-tokens.module';
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
      .state('home.preload', {
        url: '/preload',
        component: HomePreload,
        data: {
          authenticate: true
        }
      })
    .state('terms-of-service', {
      url: '/terms-of-service',
      component: TermsOfService,
      data: {
        authenticate: true
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
      .state('onboarding.services', {
        url: '/services',
        component: ServicesOnboarding,
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
    .state('kubernetes-tokens', {
      abstract: true,
      url: '/kubernetes-tokens',
      template: '<ui-view></ui-view>'
    })
      .state('kubernetes-tokens.list', {
        url: '/list/:userId',
        component: KubernetesTokensList,
        data: {
          authenticate: true,
          rolePermitted: 'admin'
        },
        resolve: {
          transition: '$transition$'
        },
        params: {
          userId: ''
        }
      })
      .state('kubernetes-tokens.new', {
        url: '/new/:userId',
        component: KubernetesTokensForm,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolePermitted: 'admin'
        }
      })
      .state('kubernetes-tokens.edit', {
        url: '/edit/:userId/:cluster',
        component: KubernetesTokensForm,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolePermitted: 'admin'
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
    })
    .state('contact-lists', {
      abstract: true,
      url: '/contact-lists',
      template: '<ui-view></ui-view>'
    })
      .state('contact-lists.list', {
        url: '/list',
        component: ContactListsList,
        data: {
          authenticate: true,
          rolePermitted: 'admin'
        }
      })
      .state('contact-lists.new', {
        url: '/new',
        component: ContactListsForm,
        data: {
          authenticate: true,
          rolePermitted: 'admin'
        }
      })
      .state('contact-lists.edit', {
        url: '/edit/:id',
        component: ContactListsForm,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolePermitted: 'admin'
        }
      })
    .state('announcements', {
      abstract: true,
      url: '/announcements',
      template: '<ui-view></ui-view>'
    })
      .state('announcements.editor', {
        abstract: true,
        url: '/editor',
        template: '<ui-view></ui-view>'
      })
        .state('announcements.editor.list', {
          url: '/list',
          component: AnnouncementsEditorList,
          data: {
            authenticate: true,
            rolePermitted: 'admin'
          }
        })
        .state('announcements.editor.new', {
          url: '/new',
          component: AnnouncementsEditorForm,
          data: {
            authenticate: true,
            rolePermitted: 'admin'
          }
        })
        .state('announcements.editor.edit', {
          url: '/edit/:id',
          component: AnnouncementsEditorForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            rolePermitted: 'admin'
          }
        })
      .state('announcements.global', {
        url: '/global',
        component: GlobalAnnouncements,
        data: {
          authenticate: true
        }
      });
};
