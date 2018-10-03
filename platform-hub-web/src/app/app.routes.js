import {
  AnnouncementsEditorForm,
  AnnouncementsEditorList,
  AnnouncementTemplatesDetail,
  AnnouncementTemplatesForm,
  AnnouncementTemplatesList,
  GlobalAnnouncements
} from './announcements/announcements.module';
import {AppSettingsForm} from './app-settings/app-settings.module';
import {
  ContactListsForm,
  ContactListsList
} from './contact-lists/contact-lists.module';
import {
  CostsReportsDetail,
  CostsReportsForm,
  CostsReportsList
} from './costs-reports/costs-reports.module';
import {
  DocsSourcesDetail,
  DocsSourcesForm,
  DocsSourcesList,
  PinnedHelpEntriesForm
} from './docs-sources/docs-sources.module';
import {
  FeatureFlagsForm
} from './feature-flags/feature-flags.module';
import {
  Faq,
  Search,
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
  KubernetesClustersDetail,
  KubernetesClustersForm,
  KubernetesClustersList,
  KubernetesGroupsDetail,
  KubernetesGroupsForm,
  KubernetesGroupsList,
  KubernetesNamespacesForm,
  KubernetesNamespacesList,
  KubernetesRobotTokensForm,
  KubernetesRobotTokensList,
  KubernetesTokensSync,
  KubernetesUserTokensForm,
  KubernetesUserTokensList
} from './kubernetes/kubernetes.module';
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
  ProjectsList,
  ProjectServicesDetail,
  ProjectServicesForm
} from './projects/projects.module';
import {
  QaEntriesDetail,
  QaEntriesForm,
  QaEntriesList
} from './qa-entries/qa-entries.module';
import {TermsOfService} from './terms-of-service/terms-of-service.module';
import {UsersList} from './users/users.module';

export const appRoutes = function ($stateProvider, $urlRouterProvider, $locationProvider, featureFlagKeys) {
  'ngInject';

  $locationProvider.html5Mode(true);
  $locationProvider.hashPrefix('!');

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
    .state('kubernetes', {
      abstract: true,
      url: '/kubernetes',
      template: '<ui-view></ui-view>'
    })
      .state('kubernetes.tokens-sync', {
        url: '/tokens-sync',
        component: KubernetesTokensSync,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          featureFlags: [
            featureFlagKeys.kubernetesTokensSync,
            featureFlagKeys.kubernetesTokens
          ],
          rolesPermitted: ['admin']
        }
      })
      .state('kubernetes.clusters', {
        abstract: true,
        url: '/clusters',
        template: '<ui-view></ui-view>'
      })
        .state('kubernetes.clusters.list', {
          url: '/list',
          component: KubernetesClustersList,
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          }
        })
        .state('kubernetes.clusters.detail', {
          url: '/detail/:id',
          component: KubernetesClustersDetail,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.projects],
            rolesPermitted: ['admin']
          }
        })
        .state('kubernetes.clusters.new', {
          url: '/new',
          component: KubernetesClustersForm,
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          }
        })
        .state('kubernetes.clusters.edit', {
          url: '/edit/:id',
          component: KubernetesClustersForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          }
        })
      .state('kubernetes.groups', {
        abstract: true,
        url: '/groups',
        template: '<ui-view></ui-view>'
      })
        .state('kubernetes.groups.list', {
          url: '/list?per_page',
          component: KubernetesGroupsList,
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          }
        })
        .state('kubernetes.groups.detail', {
          url: '/detail/:id',
          component: KubernetesGroupsDetail,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.projects],
            rolesPermitted: ['admin']
          }
        })
        .state('kubernetes.groups.new', {
          url: '/new',
          component: KubernetesGroupsForm,
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          }
        })
        .state('kubernetes.groups.edit', {
          url: '/edit/:id',
          component: KubernetesGroupsForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          }
        })
      .state('kubernetes.namespaces', {
        abstract: true,
        url: '/namespaces',
        template: '<ui-view></ui-view>'
      })
        .state('kubernetes.namespaces.list', {
          url: '/list/:cluster?per_page',
          component: KubernetesNamespacesList,
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          },
          resolve: {
            transition: '$transition$'
          },
          params: {
            cluster: ''
          }
        })
        .state('kubernetes.namespaces.new', {
          url: '/new/:cluster?fromProject&fromService',
          component: KubernetesNamespacesForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          },
          params: {
            cluster: '',
            fromProject: null,
            fromService: null
          }
        })
        .state('kubernetes.namespaces.edit', {
          url: '/edit/:cluster/:namespaceId?fromProject&fromService',
          component: KubernetesNamespacesForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          },
          params: {
            fromProject: null,
            fromService: null
          }
        })
      .state('kubernetes.user-tokens', {
        abstract: true,
        url: '/user-tokens',
        template: '<ui-view></ui-view>'
      })
        .state('kubernetes.user-tokens.list', {
          url: '/list/:userId',
          component: KubernetesUserTokensList,
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          },
          resolve: {
            transition: '$transition$'
          },
          params: {
            userId: ''
          }
        })
        .state('kubernetes.user-tokens.new', {
          url: '/new/:userId?fromProject',
          component: KubernetesUserTokensForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens]
          },
          params: {
            userId: '',
            fromProject: null
          }
        })
        .state('kubernetes.user-tokens.edit', {
          url: '/edit/:userId/:tokenId?fromProject',
          component: KubernetesUserTokensForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens]
          },
          params: {
            fromProject: null
          }
        })
      .state('kubernetes.robot-tokens', {
        abstract: true,
        url: '/robot-tokens',
        template: '<ui-view></ui-view>'
      })
        .state('kubernetes.robot-tokens.list', {
          url: '/list/:cluster?per_page',
          component: KubernetesRobotTokensList,
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens],
            rolesPermitted: ['admin']
          },
          resolve: {
            transition: '$transition$'
          },
          params: {
            cluster: ''
          }
        })
        .state('kubernetes.robot-tokens.new', {
          url: '/new/:cluster?fromProject&fromService',
          component: KubernetesRobotTokensForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens]
          },
          params: {
            cluster: '',
            fromProject: null,
            fromService: null
          }
        })
        .state('kubernetes.robot-tokens.edit', {
          url: '/edit/:cluster/:tokenId?fromProject&fromService',
          component: KubernetesRobotTokensForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.kubernetesTokens]
          },
          params: {
            fromProject: null,
            fromService: null
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
          authenticate: true,
          featureFlags: [featureFlagKeys.projects]
        }
      })
      .state('projects.detail', {
        url: '/detail/:id',
        component: ProjectsDetail,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          featureFlags: [featureFlagKeys.projects]
        }
      })
      .state('projects.new', {
        url: '/new',
        component: ProjectsForm,
        data: {
          authenticate: true,
          featureFlags: [featureFlagKeys.projects],
          rolesPermitted: ['admin']
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
          featureFlags: [featureFlagKeys.projects],
          rolesPermitted: ['admin']
        }
      })
      .state('projects.services', {
        abstract: true,
        url: '/:projectId/services',
        template: '<ui-view></ui-view>'
      })
        .state('projects.services.detail', {
          url: '/detail/:id',
          component: ProjectServicesDetail,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.projects]
          }
        })
        .state('projects.services.new', {
          url: '/new',
          component: ProjectServicesForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.projects]
          }
        })
        .state('projects.services.edit', {
          url: '/edit/:id',
          component: ProjectServicesForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            featureFlags: [featureFlagKeys.projects]
          }
        })
    .state('users', {
      url: '/users?per_page',
      component: UsersList,
      data: {
        authenticate: true,
        rolesPermitted: ['admin']
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
      .state('help.search', {
        url: '/search?q',
        component: Search,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          featureFlags: [featureFlagKeys.helpSearch]
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
              rolesPermitted: ['admin']
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
              rolesPermitted: ['admin']
            }
          })
          .state('help.support.request-templates.new', {
            url: '/new',
            component: SupportRequestTemplatesForm,
            data: {
              authenticate: true,
              rolesPermitted: ['admin']
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
              rolesPermitted: ['admin']
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
            rolesPermitted: ['admin']
          }
        })
        .state('platform-themes.editor.new', {
          url: '/new',
          component: PlatformThemesEditorForm,
          data: {
            authenticate: true,
            rolesPermitted: ['admin']
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
            rolesPermitted: ['admin']
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
        rolesPermitted: ['admin']
      }
    })
    .state('feature-flags', {
      url: '/feature-flags/edit',
      component: FeatureFlagsForm,
      data: {
        authenticate: true,
        rolesPermitted: ['admin']
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
          rolesPermitted: ['admin']
        }
      })
      .state('contact-lists.new', {
        url: '/new',
        component: ContactListsForm,
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
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
          rolesPermitted: ['admin']
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
            rolesPermitted: ['admin']
          }
        })
        .state('announcements.editor.new', {
          url: '/new/:templateId',
          component: AnnouncementsEditorForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            rolesPermitted: ['admin']
          },
          params: {
            templateId: ''
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
            rolesPermitted: ['admin']
          }
        })
      .state('announcements.global', {
        url: '/global',
        component: GlobalAnnouncements,
        data: {
          authenticate: true
        }
      })
      .state('announcements.templates', {
        abstract: true,
        url: '/templates',
        template: '<ui-view></ui-view>'
      })
        .state('announcements.templates.list', {
          url: '/list',
          component: AnnouncementTemplatesList,
          data: {
            authenticate: true,
            rolesPermitted: ['admin']
          }
        })
        .state('announcements.templates.detail', {
          url: '/detail/:id',
          component: AnnouncementTemplatesDetail,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            rolesPermitted: ['admin']
          }
        })
        .state('announcements.templates.new', {
          url: '/new',
          component: AnnouncementTemplatesForm,
          data: {
            authenticate: true,
            rolesPermitted: ['admin']
          }
        })
        .state('announcements.templates.edit', {
          url: '/edit/:id',
          component: AnnouncementTemplatesForm,
          resolve: {
            transition: '$transition$'
          },
          data: {
            authenticate: true,
            rolesPermitted: ['admin']
          }
        })
    .state('costs-reports', {
      abstract: true,
      url: '/costs-reports',
      template: '<ui-view></ui-view>'
    })
      .state('costs-reports.list', {
        url: '/list',
        component: CostsReportsList,
        data: {
          authenticate: true,
          rolesPermitted: ['admin', 'limited_admin']
        }
      })
      .state('costs-reports.detail', {
        url: '/detail/:id',
        component: CostsReportsDetail,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolesPermitted: ['admin', 'limited_admin']
        }
      })
      .state('costs-reports.new', {
        url: '/new',
        component: CostsReportsForm,
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
    .state('docs-sources', {
      abstract: true,
      url: '/docs-sources',
      template: '<ui-view></ui-view>'
    })
      .state('docs-sources.list', {
        url: '/list',
        component: DocsSourcesList,
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
      .state('docs-sources.detail', {
        url: '/detail/:id',
        component: DocsSourcesDetail,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
      .state('docs-sources.new', {
        url: '/new',
        component: DocsSourcesForm,
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
      .state('docs-sources.edit', {
        url: '/edit/:id',
        component: DocsSourcesForm,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
    .state('pinned-help-entries', {
      url: '/pinned-help-entries/edit',
      component: PinnedHelpEntriesForm,
      data: {
        authenticate: true,
        rolesPermitted: ['admin']
      }
    })
    .state('qa-entries', {
      abstract: true,
      url: '/qa-entries',
      template: '<ui-view></ui-view>'
    })
      .state('qa-entries.list', {
        url: '/list',
        component: QaEntriesList,
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
      .state('qa-entries.detail', {
        url: '/detail/:id',
        component: QaEntriesDetail,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
      .state('qa-entries.new', {
        url: '/new',
        component: QaEntriesForm,
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      })
      .state('qa-entries.edit', {
        url: '/edit/:id',
        component: QaEntriesForm,
        resolve: {
          transition: '$transition$'
        },
        data: {
          authenticate: true,
          rolesPermitted: ['admin']
        }
      });
};
