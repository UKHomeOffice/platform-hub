export const ProjectServicesDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./project-services-detail.html'),
  controller: ProjectServicesDetailController
};

function ProjectServicesDetailController($q, $mdDialog, $state, roleCheckerService, FeatureFlags, featureFlagKeys, Projects, KubernetesNamespaces, logger) {
  'ngInject';

  const ctrl = this;

  const projectId = ctrl.transition.params().projectId;
  const id = ctrl.transition.params().id;

  ctrl.FeatureFlags = FeatureFlags;
  ctrl.featureFlagKeys = featureFlagKeys;

  ctrl.projectId = projectId;
  ctrl.loading = true;
  ctrl.isAdmin = false;
  ctrl.isProjectAdmin = false;
  ctrl.service = null;
  ctrl.kubernetesRobotTokens = [];
  ctrl.processingKubernetesRobotTokens = false;
  ctrl.processingKubernetesNamespaces = false;

  ctrl.deleteService = deleteService;
  ctrl.shouldShowCreateKubernetesRobotTokenButton = shouldShowCreateKubernetesRobotTokenButton;
  ctrl.loadKubernetesRobotTokens = loadKubernetesRobotTokens;
  ctrl.deleteKubernetesRobotToken = deleteKubernetesRobotToken;
  ctrl.loadKubernetesNamespaces = loadKubernetesNamespaces;
  ctrl.deleteKubernetesNamespace = deleteKubernetesNamespace;

  init();

  function init() {
    loadAdminStatus()
      .then(loadService);
  }

  function loadAdminStatus() {
    return roleCheckerService
      .hasHubRole('admin')
      .then(hasRole => {
        ctrl.isAdmin = hasRole;
      });
  }

  function loadService() {
    ctrl.loading = true;
    ctrl.service = null;

    const serviceFetch = Projects
      .getService(projectId, id)
      .then(service => {
        ctrl.service = service;
      });

    const adminCheck = Projects
      .membershipRoleCheck(projectId, 'admin')
      .then(data => {
        ctrl.isProjectAdmin = data.result;
      });

    return $q
      .all([serviceFetch, adminCheck])
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function deleteService(targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the service permanently from the hub.')
      .ariaLabel('Confirm deletion of project service')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        Projects
          .deleteService(projectId, ctrl.service.id)
          .then(() => {
            logger.success('Service deleted');
            $state.go('projects.detail', {id: projectId});
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }

  function shouldShowCreateKubernetesRobotTokenButton() {
    return ctrl.isAdmin || ctrl.isProjectAdmin;
  }

  function loadKubernetesRobotTokens() {
    ctrl.processingKubernetesRobotTokens = true;
    ctrl.kubernetesRobotTokens = [];

    Projects
      .getServiceKubernetesRobotTokens(projectId, ctrl.service.id)
      .then(tokens => {
        angular.copy(tokens, ctrl.kubernetesRobotTokens);
      })
      .finally(() => {
        ctrl.processingKubernetesRobotTokens = false;
      });
  }

  function deleteKubernetesRobotToken(id, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete this kubernetes robot token permanently.')
      .ariaLabel('Confirm deletion of a kubernetes robot token for this project service')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processingKubernetesRobotTokens = true;

        Projects
          .deleteServiceKubernetesRobotToken(projectId, ctrl.service.id, id)
          .then(() => {
            logger.success('Token deleted');
            return loadKubernetesRobotTokens();
          })
          .finally(() => {
            ctrl.processingKubernetesRobotTokens = false;
          });
      });
  }

  function loadKubernetesNamespaces() {
    ctrl.processingKubernetesNamespaces = true;
    ctrl.kubernetesNamespaces = [];

    KubernetesNamespaces
      .getAllByService(ctrl.service.id)
      .then(namespaces => {
        angular.copy(namespaces, ctrl.kubernetesNamespaces);
      })
      .finally(() => {
        ctrl.processingKubernetesNamespaces = false;
      });
  }

  function deleteKubernetesNamespace(id, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete this kubernetes namespace from the hub. NOTE: this doesn\'t actually delete the namespace from the cluster - it just deletes the registration with this service.')
      .ariaLabel('Confirm unregistration of a kubernetes namespace for this project service')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processingKubernetesNamespaces = true;

        KubernetesNamespaces
          .delete(id)
          .then(() => {
            logger.success('Namespace deleted');
            return loadKubernetesNamespaces();
          })
          .finally(() => {
            ctrl.processingKubernetesNamespaces = false;
          });
      });
  }
}
