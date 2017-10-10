export const ProjectServiceSelectorPopupController = function ($mdDialog, Projects, serviceIsOptional) {
  'ngInject';

  const ctrl = this;

  ctrl.Projects = Projects;
  ctrl.serviceIsOptional = serviceIsOptional;

  ctrl.loading = true;
  ctrl.selectedProject = null;
  ctrl.services = [];
  ctrl.selectedService = null;

  ctrl.handleProjectChanged = handleProjectChanged;
  ctrl.cancel = $mdDialog.cancel;
  ctrl.chooseProject = chooseProject;
  ctrl.chooseService = chooseService;

  init();

  function init() {
    Projects
      .refresh()
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function handleProjectChanged() {
    ctrl.loading = true;
    ctrl.services = [];
    ctrl.selectedService = null;

    Projects
      .getServices(ctrl.selectedProject.id)
      .then(services => {
        ctrl.services = services;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function chooseProject() {
    $mdDialog.hide({
      project: ctrl.selectedProject,
      service: null
    });
  }

  function chooseService() {
    $mdDialog.hide({
      project: ctrl.selectedProject,
      service: ctrl.selectedService
    });
  }
};
