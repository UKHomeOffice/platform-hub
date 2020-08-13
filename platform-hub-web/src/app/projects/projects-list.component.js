export const ProjectsListComponent = {
  template: require('./projects-list.html'),
  controller: ProjectsListController
};

function ProjectsListController(roleCheckerService, Projects, Me, _) {
  'ngInject';

  const ctrl = this;

  ctrl.Projects = Projects;
  ctrl.myProjects = [];
  ctrl.notMyProjects = [];

  ctrl.loading = true;
  ctrl.isAdmin = false;
  ctrl.memberships = [];

  init();

  function init() {
    loadProjects();
    loadAdminStatus();
  }

  function loadProjects() {
    ctrl.loading = true;

    return Projects.getAll()
    .then(projects => {
      return Me.refresh().then(() => {
        const currentUserId = Me.data.id;
        return Promise.all(projects.map(projectIdto => {
          return Projects.getMemberships(projectIdto.id);
        })).then(memberships => {
          ctrl.memberships = memberships;

          ctrl.myProjects = getMyProjects(projects, currentUserId, memberships);
          ctrl.notMyProjects = getNotMyProjects(projects, currentUserId, memberships);

          ctrl.myProjects = _.orderBy(ctrl.myProjects, [project => project.name.toLowerCase()], ['asc']);
          ctrl.notMyProjects = _.orderBy(ctrl.notMyProjects, [project => project.name.toLowerCase()], ['asc']);

          Projects.all = _.concat(ctrl.myProjects, ctrl.notMyProjects);

          ctrl.loading = false;
        });
      });
    });
  }

  function getMyProjects(allProjects, currentUserId, memberships) {
    return _.chain(allProjects)
    .zip(memberships)
    .filter(projectsMembershipsPair => {
      const membership = projectsMembershipsPair[1];
      return _.some(membership, {user: {id: currentUserId}});
    })
    .map(projectsMembershipsPair => {
      const project = projectsMembershipsPair[0];
      project.isProjectTeamMember = true;
      return projectsMembershipsPair;
    })
    .unzip()
    .head().value();
  }

  function getNotMyProjects(allProjects, currentUserId, memberships) {
    return _.chain(allProjects)
    .zip(memberships)
    .filter(projectsMembershipsPair => {
      const membership = projectsMembershipsPair[1];
      return !_.some(membership, {user: {id: currentUserId}});
    })
    .map(projectsMembershipsPair => {
      const project = projectsMembershipsPair[0];
      project.isProjectTeamMember = false;
      return projectsMembershipsPair;
    })
    .unzip()
    .head().value();
  }

  function loadAdminStatus() {
    roleCheckerService
    .hasHubRole('admin')
    .then(hasRole => {
      ctrl.isAdmin = hasRole;
    });
  }
}
