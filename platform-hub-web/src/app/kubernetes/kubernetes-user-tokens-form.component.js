/* eslint camelcase: 0 */

export const KubernetesUserTokensFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-user-tokens-form.html'),
  controller: KubernetesUserTokensFormController
};

function KubernetesUserTokensFormController($q, $state, $mdSelect, Projects, AppSettings, KubernetesTokens, KubernetesGroups, roleCheckerService, hubApiService, logger, _) {
  'ngInject';

  const ctrl = this;

  const transitionParams = ctrl.transition && ctrl.transition.params();

  const userId = _.get(transitionParams, 'userId');
  const tokenId = _.get(transitionParams, 'tokenId');
  const fromProject = _.get(transitionParams, 'fromProject');

  ctrl._ = _;
  ctrl.AppSettings = AppSettings;
  ctrl.Projects = Projects;

  ctrl.fromProject = fromProject;
  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.token = null;
  ctrl.allowedUsers = [];
  ctrl.allowedClusters = [];
  ctrl.possibleGroups = {};
  ctrl.allowedGroups = {};

  ctrl.canChangeProject = canChangeProject;
  ctrl.handleProjectChange = handleProjectChange;
  ctrl.handleClusterChange = handleClusterChange;
  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.loading = true;

    ctrl.isNew = !tokenId;
    ctrl.token = null;

    fetchInitialUsers()
      .then(topLevelAuthorisationChecks)
      .then(passed => {
        if (!passed) {
          return bootOut();
        }

        if (userId && fromProject) {
          // Make sure the user specified in the params is a member of the
          // project specified in the params
          const userIsMember = _.some(ctrl.allowedUsers, u => u.id === userId);
          if (!userIsMember) {
            return bootOut();
          }
        }

        return Projects
          .refresh()
          .then(setupToken);
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function fetchInitialUsers() {
    if (fromProject) {
      return fetchUsers(fromProject);
    }

    return $q.when();
  }

  function topLevelAuthorisationChecks() {
    return loadAdminStatus()
      .then(() => {
        // If not an admin, then `fromProject` param must be provided, and
        // verified for project admin status.

        if (!ctrl.isAdmin) {
          if (!fromProject) {
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

  function fetchUsers(projectId) {
    return Projects
    .getMemberships(projectId)
    .then(memberships => {
      ctrl.allowedUsers = _.map(memberships, 'user');
    });
  }

  function setupToken() {
    if (ctrl.isNew) {
      ctrl.token = {
        project: {
          id: fromProject
        },
        user: {
          id: userId,
          is_active: true
        },
        cluster: {},
        groups: []
      };

      if (fromProject) {
        return refreshForProject();
      }

      return $q.when();
    }

    // We have an existing token, people! Look sharp!

    let fetch = null;
    if (fromProject) {
      fetch = Projects
        .getKubernetesUserToken(fromProject, tokenId)
        .catch(bootOut);
    } else {
      fetch = KubernetesTokens
        .getToken(tokenId)
        .catch(bootOut);
    }

    return fetch
      .then(token => {
        ctrl.token = token;

        if (fromProject && ctrl.token.project.id !== fromProject) {
          return bootOut();
        }

        if (userId && ctrl.token.user.id !== userId) {
          return bootOut();
        }

        return refreshForProject();
      });
  }

  function canChangeProject() {
    return ctrl.isNew && ctrl.isAdmin && !ctrl.fromProject;
  }

  function handleProjectChange() {
    ctrl.processing = true;

    // Reset the token's groups as they may not be applicable to this
    // project anymore.
    if (ctrl.token) {
      ctrl.token.groups = [];
    }

    return refreshForProject()
      .finally(() => {
        ctrl.processing = false;
      });
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

  function refreshForProject() {
    return fetchUsers(ctrl.token.project.id)
      .then(fetchClusters)
      .then(fetchGroups)
      .then(filterGroups);
  }

  function fetchClusters() {
    ctrl.allowedClusters = [];

    const projectId = _.get(ctrl.token, 'project.id');

    if (projectId) {
      return Projects
        .getKubernetesClusters(projectId)
        .then(clusters => {
          ctrl.allowedClusters = clusters;
        });
    }

    return $q.when();
  }

  function fetchGroups() {
    ctrl.possibleGroups = {};
    ctrl.allowedGroups = {};

    const projectId = _.get(ctrl.token, 'project.id');

    if (projectId) {
      return Projects
        .getAllKubernetesGroupsGrouped(projectId, 'user')
        .then(grouped => {
          ctrl.possibleGroups = grouped;
        });
    }

    return $q.when();
  }

  function filterGroups() {
    ctrl.allowedGroups = [];

    const clusterName = _.get(ctrl.token, 'cluster.name');

    if (clusterName) {
      const seen = {};
      ctrl.allowedGroups = Object.keys(ctrl.possibleGroups).reduce((acc, key) => {
        const forCluster = KubernetesGroups
          .filterGroupsForCluster(ctrl.possibleGroups[key], clusterName)
          .filter(g => !g.is_privileged);

        // Need to consider dup groups between services etc.
        const dedupped = forCluster.filter(g => {
          const allowed = !seen[g.name];
          seen[g.name] = 1;
          return allowed;
        });

        if (!_.isEmpty(dedupped)) {
          acc[key] = dedupped;
        }

        return acc;
      }, {});
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
      if (fromProject) {
        promise = Projects.createKubernetesUserToken(ctrl.token.project.id, ctrl.token);
      } else {
        promise = KubernetesTokens.createUserToken(ctrl.token.user.id, ctrl.token);
      }

      promise = promise
        .then(() => {
          logger.success('New kubernetes robot token created');
        });
    } else {
      if (fromProject) {
        promise = Projects.updateKubernetesUserToken(ctrl.token.project.id, ctrl.token.id, ctrl.token);
      } else {
        promise = KubernetesTokens.updateUserToken(ctrl.token.id, ctrl.token);
      }

      promise = promise
        .then(() => {
          logger.success('Kubernetes robot token updated');
        });
    }

    return promise
      .then(() => {
        if (fromProject) {
          $state.go('projects.detail', {id: fromProject});
        } else {
          $state.go('kubernetes.user-tokens.list', {userId: ctrl.token.user.id});
        }
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
