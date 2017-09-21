export const ProjectServicesFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./project-services-form.html'),
  controller: ProjectServicesFormController
};

function ProjectServicesFormController($state, Projects, logger) {
  'ngInject';

  const ctrl = this;

  const projectId = ctrl.transition.params().projectId;
  const id = ctrl.transition.params().id;

  ctrl.projectId = projectId;
  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.service = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.service = {};
      ctrl.loading = false;
    } else {
      loadService();
    }
  }

  function loadService() {
    ctrl.loading = true;
    ctrl.service = null;

    Projects
      .getService(projectId, id)
      .then(service => {
        ctrl.service = service;
      }).finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.serviceForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      Projects
        .createService(projectId, ctrl.service)
        .then(service => {
          logger.success('New project service created');
          goToServiceDetailPage(service.id);
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      Projects
        .updateService(projectId, ctrl.service.id, ctrl.service)
        .then(service => {
          logger.success('Project service updated');
          goToServiceDetailPage(service.id);
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }

  function goToServiceDetailPage(serviceId) {
    $state.go('projects.services.detail', {
      projectId,
      id: serviceId
    });
  }
}
