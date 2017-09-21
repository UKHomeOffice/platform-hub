export const ProjectServicesDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./project-services-detail.html'),
  controller: ProjectServicesDetailController
};

function ProjectServicesDetailController($mdDialog, $state, Projects, logger) {
  'ngInject';

  const ctrl = this;

  const projectId = ctrl.transition.params().projectId;
  const id = ctrl.transition.params().id;

  ctrl.projectId = projectId;
  ctrl.loading = true;
  ctrl.service = null;

  ctrl.deleteService = deleteService;

  init();

  function init() {
    loadService();
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
}
