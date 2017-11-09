export const ProjectsListComponent = {
  template: require('./projects-list.html'),
  controller: ProjectsListController
};

function ProjectsListController(roleCheckerService, Projects) {
  'ngInject';

  const ctrl = this;

  ctrl.Projects = Projects;

  ctrl.loading = true;
  ctrl.isAdmin = false;

  init();

  function init() {
    loadProjects();
    loadAdminStatus();
  }

  function loadProjects() {
    ctrl.loading = true;

    Projects
      .refresh()
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
