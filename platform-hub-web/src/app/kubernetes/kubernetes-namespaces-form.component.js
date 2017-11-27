/* eslint camelcase: 0 */

export const KubernetesNamespacesFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./kubernetes-namespaces-form.html'),
  controller: KubernetesNamespacesFormController
};

function KubernetesNamespacesFormController($q, $state, $mdSelect, projectServiceSelectorPopupService, AppSettings, KubernetesNamespaces, Projects, logger, _) {
  'ngInject';

  const ctrl = this;

  const transitionParams = ctrl.transition && ctrl.transition.params();

  const cluster = _.get(transitionParams, 'cluster');
  const namespaceId = _.get(transitionParams, 'namespaceId');
  const fromProject = _.get(transitionParams, 'fromProject');
  const fromService = _.get(transitionParams, 'fromService');

  ctrl.AppSettings = AppSettings;

  ctrl.fromProject = fromProject;
  ctrl.fromService = fromService;
  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.namespace = null;
  ctrl.service = null;
  ctrl.allowedClusters = {};

  ctrl.canChangeService = canChangeService;
  ctrl.chooseService = chooseService;
  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.loading = true;

    ctrl.isNew = !namespaceId;
    ctrl.namespace = null;

    if (
      (!fromProject && fromService) ||
      (fromProject && !fromService)
    ) {
      logger.error('Bug detected: both `fromProject` and `fromService` need to be provided, or neither');
      $state.go('home');
      return;
    }

    return setupNamespaceAndFetchService()
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function setupNamespaceAndFetchService() {
    if (ctrl.isNew) {
      ctrl.namespace = {
        cluster: {
          name: cluster
        }
      };

      if (fromService) {
        return fetchService(fromProject, fromService);
      }

      return $q.when();
    }

    return KubernetesNamespaces
      .get(namespaceId)
      .then(namespace => {
        ctrl.namespace = namespace;

        if (fromService && ctrl.namespace.service.id !== fromService) {
          logger.error('Bad data detected: namespace has a service assigned that doesn\'t match the service expected');
          $state.go('home');
          return $q.reject();
        }

        return fetchService(ctrl.namespace.service.project.id, ctrl.namespace.service.id);
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
    return ctrl.isNew && !ctrl.fromService;
  }

  function chooseService(targetEvent) {
    if (!canChangeService()) {
      return;
    }

    return projectServiceSelectorPopupService
      .openForServiceOnly(targetEvent)
      .then(result => {
        ctrl.service = result.service;
      })
      .then(handleServiceChange);
  }

  function handleServiceChange() {
    ctrl.processing = true;

    return fetchClusters()
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

  function createOrUpdate() {
    if (ctrl.kubernetesNamespaceForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    let promise = null;

    if (ctrl.isNew) {
      const data = {
        service_id: ctrl.service.id,
        cluster_name: ctrl.namespace.cluster.name,
        name: ctrl.namespace.name,
        description: ctrl.namespace.description
      };

      promise = KubernetesNamespaces
        .create(data)
        .then(() => {
          logger.success('New Kubernetes namespace created');
        });
    } else {
      const data = {
        description: ctrl.namespace.description
      };

      promise = KubernetesNamespaces
        .update(namespaceId, data)
        .then(() => {
          logger.success('Kubernetes namespace updated');
        });
    }

    return promise
      .then(() => {
        if (fromService) {
          $state.go('projects.services.detail', {projectId: fromProject, id: fromService});
        } else {
          $state.go('kubernetes.namespaces.list', {cluster: ctrl.namespace.cluster.name});
        }
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
