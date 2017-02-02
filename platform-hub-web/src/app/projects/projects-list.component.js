export const ProjectsListComponent = {
  template: require('./projects-list.html'),
  controller: ProjectsListController
};

function ProjectsListController(roleCheckerService, hubApiService) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.isAdmin = false;
  ctrl.projects = [];

  init();

  function init() {
    loadProjects();
    loadAdminStatus();
  }

  function loadProjects() {
    ctrl.loading = true;
    ctrl.projects = [];

    hubApiService
      .getProjects()
      .then(projects => {
        ctrl.projects = projects;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function loadAdminStatus() {
    roleCheckerService
      .hasHubRole('admin')
      .then(hasRole => {
        ctrl.isAdmin = hasRole;
      });
  }
}
