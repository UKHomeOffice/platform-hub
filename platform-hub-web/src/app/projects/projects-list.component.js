export const ProjectsListComponent = {
  template: require('./projects-list.html'),
  controller: ProjectsListController
};

function ProjectsListController(roleCheckerService, Projects, Me, _) {
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

    return Projects.getAll()
    .then(projects => {
      return Me.refresh().then(() => {
        const currentUserId = Me.data.id;
        return Promise.all(projects.map(projectIdto => {
          return Projects.getMemberships(projectIdto.id);
        })).then(memberships => {
          const myProjects = getProjects(projects, currentUserId, memberships, true);
          const notMyProjects = getProjects(projects, currentUserId, memberships, false);

          Projects.all = _.concat(myProjects, notMyProjects);

          ctrl.loading = false;
        });
      });
    });
  }

  function getProjects(allProjects, currentUserId, memberships, myProjects) {
    return _.chain(allProjects)
    .zip(memberships)
    .filter(projectsMembershipsPair => {
      const membership = projectsMembershipsPair[1];
      const userIsProjectMember = _.some(membership, {user: {id: currentUserId}});
      return myProjects ? userIsProjectMember : !userIsProjectMember;
    })
    .map(projectsMembershipsPair => {
      const project = projectsMembershipsPair[0];
      project.isProjectTeamMember = myProjects;
      if (myProjects) {
        const membership = projectsMembershipsPair[1];
        if (_.some(membership, {user: {id: currentUserId}, role: 'admin'})) {
          project.isProjectAdmin = true;
        }
      }
      return projectsMembershipsPair;
    })
    .unzip()
    .head()
    .orderBy([project => project.name.toLowerCase()], ['asc'])
    .value();
  }

  function loadAdminStatus() {
    roleCheckerService
    .hasHubRole('admin')
    .then(hasRole => {
      ctrl.isAdmin = hasRole;
    });
  }
}
