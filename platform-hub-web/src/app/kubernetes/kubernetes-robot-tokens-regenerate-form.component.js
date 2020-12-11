export const KubernetesRobotTokensRegenerateFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-robot-tokens-regenerate-form.html'),
  controller: KubernetesRobotTokensRegenerateFormController
};

function KubernetesRobotTokensRegenerateFormController($q, $state, $mdDialog, $mdSelect, roleCheckerService, projectServiceSelectorPopupService, AppSettings, KubernetesTokens, KubernetesGroups, Projects, logger, _) {
  'ngInject';

  const ctrl = this;

  const transitionParams = ctrl.transition && ctrl.transition.params();

  // const cluster = _.get(transitionParams, 'cluster');
  const tokenId = _.get(transitionParams, 'tokenId');
  const fromProject = _.get(transitionParams, 'fromProject');
  const fromService = _.get(transitionParams, 'fromService');

  ctrl.AppSettings = AppSettings;

  ctrl.fromProject = fromProject;
  ctrl.fromService = fromService;
  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.saving = false;
  ctrl.isAdmin = false;
  ctrl.token = null;
  ctrl.service = null;
  ctrl.allowedClusters = [];
  ctrl.possibleGroups = [];
  ctrl.allowedGroups = [];
  ctrl.expiryOptions = [
    {label: 'No expiration', value: null},
    {label: '1 day', value: 24 * 60 * 60},
    {label: '3 days', value: 3 * 24 * 60 * 60},
    {label: '7 days', value: 7 * 24 * 60 * 60},
    {label: '30 days', value: 30 * 24 * 60 * 60},
    {label: '90 days', value: 90 * 24 * 60 * 60}
  ];

  ctrl.createOrUpdate = createOrUpdate;
  ctrl.regenerateToken = regenerateToken;

  init();

  function init() {
    ctrl.loading = true;

    ctrl.token = null;

    if (
      (!fromProject && fromService) ||
      (fromProject && !fromService)
    ) {
      return bootOut();
    }

    topLevelAuthorisationChecks()
    .then(passed => {
      if (!passed) {
        return bootOut();
      }

      return setupTokenAndFetchService();
    })
    .finally(() => {
      ctrl.loading = false;
    });
  }

  function topLevelAuthorisationChecks() {
    return loadAdminStatus()
    .then(() => {
      // If not an admin, then `fromProject` and `fromService` params must be
      // provided, and verified for project admin status.

      if (!ctrl.isAdmin) {
        if (!fromProject || !fromService) {
          return false;
        }

        return Projects
        .membershipRoleCheck(fromProject, 'admin')
        .then(data => data.result);
      }

      return true;
    });
  }

  function loadAdminStatus() {
    return roleCheckerService
    .hasHubRole('admin')
    .then(hasRole => {
      ctrl.isAdmin = hasRole;
    });
  }

  function bootOut() {
    logger.error('You are not allowed to access this form!');
    $state.go('home');
    return $q.reject();
  }

  function setupTokenAndFetchService() {
    // We have an existing token, people! Look sharp!

    let fetch = null;
    if (fromService) {
      fetch = Projects
      .getServiceKubernetesRobotToken(fromProject, fromService, tokenId)
      .catch(bootOut);
    } else {
      fetch = KubernetesTokens
      .getToken(tokenId)
      .catch(bootOut);
    }

    return fetch
    .then(token => {
      ctrl.token = token;

      if (fromService && ctrl.token.service.id !== fromService) {
        return bootOut();
      }

      return fetchService(ctrl.token.service.project.id, ctrl.token.service.id).catch(bootOut);
    });
  }

  function fetchService(projectId, serviceId) {
    return Projects
    .getService(projectId, serviceId)
    .then(service => {
      ctrl.service = service;
    })
    .then(handleServiceChange);
  }

  function handleServiceChange() {
    ctrl.processing = true;

    return fetchClusters()
    .then(fetchGroups)
    .then(filterGroups)
    .finally(() => {
      ctrl.processing = false;
    });
  }

  function fetchClusters() {
    ctrl.allowedClusters = [];

    if (ctrl.service) {
      return Projects
      .getKubernetesClusters(ctrl.service.project.id)
      .then(clusters => {
        ctrl.allowedClusters = clusters;
      });
    }

    return $q.when();
  }

  function fetchGroups() {
    ctrl.possibleGroups = [];
    ctrl.allowedGroups = [];

    if (ctrl.service) {
      const projectGroupsFetch = Projects.getKubernetesGroups(ctrl.service.project.id, 'robot');

      const serviceGroupsFetch = Projects.getServiceKubernetesGroups(ctrl.service.project.id, ctrl.service.id, 'robot');

      return $q
      .all([projectGroupsFetch, serviceGroupsFetch])
      .then(data => {
        ctrl.possibleGroups = _.uniq(_.concat(...data));
      });
    }

    return $q.when();
  }

  function filterGroups() {
    ctrl.allowedGroups = [];

    const clusterName = _.get(ctrl.token, 'cluster.name');

    if (clusterName) {
      ctrl.allowedGroups = KubernetesGroups
      .filterGroupsForCluster(ctrl.possibleGroups, clusterName)
      .filter(g => !g.is_privileged);
    }
  }

  function createOrUpdate() {
    if (ctrl.kubernetesTokenForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    let promise = null;

    if (fromService) {
      promise = Projects.createServiceKubernetesRobotToken(fromProject, ctrl.service.id, ctrl.token);
    } else {
      promise = KubernetesTokens.createRobotToken(ctrl.service.id, ctrl.token);
    }

    promise = promise
    .then(() => {
      logger.success('New kubernetes robot token created');
    });

    return promise
    .then(() => {
      if (fromService) {
        $state.go('projects.services.detail', {projectId: fromProject, id: fromService});
      } else {
        $state.go('kubernetes.robot-tokens.list', {cluster: ctrl.token.cluster.name});
      }
    })
    .finally(() => {
      ctrl.saving = false;
    });
  }

  function regenerateToken(targetEvent) {
    const confirm = $mdDialog.confirm()
    .title(`Are you sure?`)
    .textContent(`This will delete the previous token permanently and create a new token.`)
    .ariaLabel('Confirm token deletion')
    .targetEvent(targetEvent)
    .ok('Do it')
    .cancel('Cancel');

    $mdDialog
    .show(confirm)
    .then(() => {
      ctrl.busy = true;

      let promise = null;

      if (ctrl.fromProject) {
        if (ctrl.token.kind === 'robot') {
          promise = Projects.deleteServiceKubernetesRobotToken(ctrl.fromProject, ctrl.fromService, ctrl.token.id);
        }
      } else {
        promise = KubernetesTokens.deleteToken(ctrl.token.id);
      }

      return promise
      .then(() => {
        createOrUpdate();
      })
      .finally(() => {
        ctrl.busy = false;
      });
    });
  }
}
