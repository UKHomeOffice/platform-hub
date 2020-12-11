export const KubernetesRobotTokensFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-robot-tokens-form.html'),
  controller: KubernetesRobotTokensFormController
};

function KubernetesRobotTokensFormController($q, $state, $mdSelect, roleCheckerService, projectServiceSelectorPopupService, AppSettings, KubernetesTokens, KubernetesGroups, Projects, logger, _) {
  'ngInject';

  const ctrl = this;

  const transitionParams = ctrl.transition && ctrl.transition.params();

  const cluster = _.get(transitionParams, 'cluster');
  const tokenId = _.get(transitionParams, 'tokenId');
  const fromProject = _.get(transitionParams, 'fromProject');
  const fromService = _.get(transitionParams, 'fromService');

  ctrl.AppSettings = AppSettings;

  ctrl.fromProject = fromProject;
  ctrl.fromService = fromService;
  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.isAdmin = false;
  ctrl.token = null;
  ctrl.service = null;
  ctrl.allowedClusters = [];
  ctrl.possibleGroups = [];
  ctrl.allowedGroups = [];
  ctrl.expiryOptions = [
    {label: 'No expiration', value: null},
    {label: '10 seconds', value: 10},
    {label: '30 days', value: 30 * 24 * 60 * 60},
    {label: '90 days', value: 90 * 24 * 60 * 60}
  ];

  ctrl.canChangeService = canChangeService;
  ctrl.chooseService = chooseService;
  ctrl.handleClusterChange = handleClusterChange;
  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.loading = true;

    ctrl.isNew = !tokenId;
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
    if (ctrl.isNew) {
      ctrl.token = {
        cluster: {
          name: cluster
        },
        groups: []
      };

      if (fromService) {
        return fetchService(fromProject, fromService).catch(bootOut);
      }

      return $q.when();
    }

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

  function canChangeService() {
    return ctrl.isNew && ctrl.isAdmin && !ctrl.fromService;
  }

  function chooseService(targetEvent) {
    if (!canChangeService()) {
      return;
    }

    return projectServiceSelectorPopupService
      .openForServiceOnly(targetEvent)
      .then(result => {
        ctrl.service = result.service;

        // Reset the token's groups as they may not be applicable to this
        // service anymore.
        if (ctrl.token) {
          ctrl.token.groups = [];
        }
      })
      .then(handleServiceChange);
  }

  function handleClusterChange() {
    ctrl.processing = true;

    // Reset the token's groups as they may not be applicable to the cluster anymore.
    ctrl.token.groups = [];

    // See: https://github.com/angular/material/issues/10747
    $mdSelect
      .hide()
      .then(filterGroups)
      .finally(() => {
        ctrl.processing = false;
      });
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

    if (ctrl.isNew) {
      if (fromService) {
        promise = Projects.createServiceKubernetesRobotToken(fromProject, ctrl.service.id, ctrl.token);
      } else {
        promise = KubernetesTokens.createRobotToken(ctrl.service.id, ctrl.token);
      }

      promise = promise
        .then(() => {
          logger.success('New kubernetes robot token created');
        });
    } else {
      if (fromService) {
        promise = Projects.updateServiceKubernetesRobotToken(fromProject, ctrl.service.id, ctrl.token.id, ctrl.token);
      } else {
        promise = KubernetesTokens.updateRobotToken(tokenId, ctrl.token);
      }

      promise = promise
        .then(() => {
          logger.success('Kubernetes robot token updated');
        });
    }

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
}
