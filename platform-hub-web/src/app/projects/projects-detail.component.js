export const ProjectsDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./projects-detail.html'),
  controller: ProjectsDetailController
};

function ProjectsDetailController($q, $mdDialog, $state, roleCheckerService, hubApiService, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.isAdmin = false;
  ctrl.project = null;
  ctrl.memberships = [];
  ctrl.searchSelectedUser = null;
  ctrl.searchText = '';

  ctrl.deleteProject = deleteProject;
  ctrl.searchUsers = searchUsers;
  ctrl.addMembership = addMembership;
  ctrl.removeMembership = removeMembership;
  ctrl.makeManager = makeManager;
  ctrl.demoteManager = demoteManager;

  init();

  function init() {
    loadProject();
    loadAdminStatus();
  }

  function loadProject() {
    ctrl.loading = true;
    ctrl.project = null;
    ctrl.searchSelectedUser = null;
    ctrl.searchText = '';

    const projectFetch = hubApiService
      .getProject(id)
      .then(project => {
        ctrl.project = project;
      });

    const membershipsFetch = hubApiService
      .getProjectMemberships(id)
      .then(memberships => {
        ctrl.memberships = memberships;
      });

    $q
      .all([projectFetch, membershipsFetch])
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

  function deleteProject(targetEvent) {
    if (!ctrl.isAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the project permanently from the Platform Hub.')
      .ariaLabel('Confirm deletion of project')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .deleteProject(ctrl.project.id)
          .then(() => {
            logger.success('Project deleted');
            $state.go('projects.list');
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }

  function searchUsers(query) {
    return hubApiService.searchUsers(query);
  }

  function addMembership() {
    if (!ctrl.isAdmin) {
      return;
    }

    hubApiService
      .addProjectMembership(ctrl.project.id, ctrl.searchSelectedUser.id)
      .then(() => {
        logger.success('Team member added to project');
        loadProject();
      });
  }

  function removeMembership(membership, targetEvent) {
    if (!ctrl.isAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will remove this person from the project (though you can add them back again later).')
      .ariaLabel('Confirm removal of team member from project')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .removeProjectMembership(ctrl.project.id, membership.user.id)
          .then(() => {
            logger.success('Team member removed from project');
            loadProject();
          });
      });
  }

  function makeManager(membership, targetEvent) {
    if (!ctrl.isAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will make this person a team manager of the project (giving them certain priviledges).')
      .ariaLabel('Confirm making this person a team manager.')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .projectSetRole(ctrl.project.id, membership.user.id, 'manager')
          .then(() => {
            logger.success('Team member promoted to manager!');
            loadProject();
          });
      });
  }

  function demoteManager(membership, targetEvent) {
    if (!ctrl.isAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will demote this person from their team manager role in the project (though they will still be a member of the project).')
      .ariaLabel('Confirm demotion of a project team manager.')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .projectUnsetRole(ctrl.project.id, membership.user.id, 'manager')
          .then(() => {
            logger.success('Team member demoted from manager role!');
            loadProject();
          });
      });
  }
}
