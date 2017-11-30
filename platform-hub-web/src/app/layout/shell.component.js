export const ShellComponent = {
  template: require('./shell.html'),
  controller: ShellController
};

function ShellController($scope, $mdSidenav, authService, roleCheckerService, events, icons, AppSettings, PlatformThemes, Me, FeatureFlags, featureFlagKeys, _) {
  'ngInject';

  $scope._ = _;

  const ctrl = this;

  ctrl.AppSettings = AppSettings;
  ctrl.PlatformThemes = PlatformThemes;
  ctrl.FeatureFlags = FeatureFlags;
  ctrl.Me = Me;
  ctrl.announcementsIcon = icons.announcements;
  ctrl.homeIcon = icons.home;
  ctrl.platformThemeIcon = icons.platformThemes;

  ctrl.isAdmin = false;

  ctrl.flagMessages = [
    {
      flag: 'agreed_to_terms_of_service',
      state: 'terms-of-service',
      text: 'Agree to the Terms of Service'
    },
    {
      flag: 'completed_hub_onboarding',
      state: 'onboarding.hub-setup',
      text: 'Complete your hub setup'
    },
    {
      flag: 'completed_services_onboarding',
      state: 'onboarding.services',
      text: 'Complete your services onboarding'
    }
  ];

  ctrl.myAccountNavStates = [
    {
      title: 'Terms of Service',
      state: 'terms-of-service',
      icon: icons.termsOfService
    },
    {
      title: 'Hub Setup',
      state: 'onboarding.hub-setup',
      icon: icons.hubSetup
    },
    {
      title: 'Services Onboarding',
      state: 'onboarding.services',
      icon: icons.services
    },
    {
      title: 'Connected Identities',
      state: 'identities',
      icon: icons.identities
    }
  ];

  ctrl.orgNavStates = [
    {
      title: 'Projects',
      state: 'projects.list',
      activeState: 'projects',
      icon: icons.projects,
      featureFlags: [featureFlagKeys.projects]
    }
  ];

  ctrl.helpNavStates = [
    {
      title: 'FAQ',
      state: 'help.faq',
      icon: icons.faq
    },
    {
      title: 'Support Requests',
      state: 'help.support.requests.overview',
      activeState: 'help.support.requests',
      icon: icons.supportRequests
    }
  ];

  ctrl.adminNavStates = [
    {
      title: 'Announcements',
      state: 'announcements.editor.list',
      activeState: 'announcements.editor',
      icon: ctrl.announcementsIcon
    },
    {
      title: 'Announcement Templates',
      state: 'announcements.templates.list',
      activeState: 'announcements.templates',
      icon: ctrl.announcementsIcon
    },
    {
      title: 'Users',
      state: 'users',
      icon: icons.users
    },
    {
      title: 'Platform Themes',
      state: 'platform-themes.editor.list',
      activeState: 'platform-themes.editor',
      icon: ctrl.platformThemeIcon
    },
    {
      title: 'Support Request Templates',
      state: 'help.support.request-templates.list',
      activeState: 'help.support.request-templates',
      icon: icons.supportRequests
    },
    {
      title: 'Contact Lists',
      state: 'contact-lists.list',
      icon: icons.contactList
    },
    {
      title: 'Kubernetes Tokens Sync',
      state: 'kubernetes.tokens-sync',
      icon: icons.syncTokens,
      featureFlags: [
        featureFlagKeys.kubernetesTokensSync,
        featureFlagKeys.kubernetesTokens
      ]
    },
    {
      title: 'Kubernetes Clusters',
      state: 'kubernetes.clusters.list',
      icon: icons.kubernetesClusters,
      featureFlags: [featureFlagKeys.kubernetesTokens]
    },
    {
      title: 'Kubernetes RBAC Groups',
      state: 'kubernetes.groups.list',
      icon: icons.kubernetesGroups,
      featureFlags: [featureFlagKeys.kubernetesTokens]
    },
    {
      title: 'Kubernetes Namespaces',
      state: 'kubernetes.namespaces.list',
      icon: icons.kubernetesNamespaces,
      featureFlags: [featureFlagKeys.kubernetesTokens]
    },
    {
      title: 'Kubernetes User Tokens',
      state: 'kubernetes.user-tokens.list',
      icon: icons.kubernetesTokens,
      featureFlags: [featureFlagKeys.kubernetesTokens]
    },
    {
      title: 'Kubernetes Robot Tokens',
      state: 'kubernetes.robot-tokens.list',
      icon: icons.kubernetesTokens,
      featureFlags: [featureFlagKeys.kubernetesTokens]
    },
    {
      title: 'Feature Flags',
      state: 'feature-flags',
      icon: icons.featureFlags
    },
    {
      title: 'App Settings',
      state: 'app-settings',
      icon: icons.appSettings
    }
  ];

  ctrl.toggleMenu = toggleMenu;
  ctrl.isAuthenticated = isAuthenticated;
  ctrl.shouldShowSection = shouldShowSection;

  init();

  function init() {
    $scope.$on(events.auth.updated, () => {
      if (isAuthenticated()) {
        refresh();
      } else {
        ctrl.isAdmin = false;
      }
    });

    if (isAuthenticated()) {
      refresh();
    }
  }

  function refresh() {
    loadAdminStatus();
    PlatformThemes.refresh();
  }

  function loadAdminStatus() {
    roleCheckerService
      .hasHubRole('admin')
      .then(hasRole => {
        ctrl.isAdmin = hasRole;
      });
  }

  function toggleMenu() {
    $mdSidenav('left').toggle();
  }

  function isAuthenticated() {
    return authService.isAuthenticated();
  }

  function shouldShowSection(section) {
    return section.some(e => {
      return !_.has(e, 'featureFlags') || FeatureFlags.allEnabled(e.featureFlags);
    });
  }
}
