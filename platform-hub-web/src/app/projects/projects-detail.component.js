export const ProjectsDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./projects-detail.html'),
  controller: ProjectsDetailController
};

function ProjectsDetailController($rootScope, $q, $mdDialog, $state, roleCheckerService, hubApiService, logger, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.isAdmin = false;
  ctrl.isProjectManager = false;
  ctrl.project = null;
  ctrl.memberships = [];
  ctrl.searchSelectedUser = null;
  ctrl.searchText = '';
  ctrl.processing = false;

  ctrl.deleteProject = deleteProject;
  ctrl.searchUsers = searchUsers;
  ctrl.shouldShowActionsMenu = shouldShowActionsMenu;
  ctrl.addMembership = addMembership;
  ctrl.removeMembership = removeMembership;
  ctrl.makeManager = makeManager;
  ctrl.demoteManager = demoteManager;
  ctrl.allowOnboardOrOffboardGitHub = allowOnboardOrOffboardGitHub;
  ctrl.userOnboardGitHub = userOnboardGitHub;
  ctrl.userOffboardGitHub = userOffboardGitHub;

  init();

  function init() {
    loadProject();
    loadAdminStatus();
  }

  function loadProject() {
    ctrl.loading = true;
    ctrl.isProjectManager = false;
    ctrl.project = null;
    ctrl.memberships = [];
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

        // Check to see if logged in user is a project team manager
        const currentUserId = $rootScope.currentUserId;
        if (currentUserId) {
          ctrl.isProjectManager = _.some(memberships, m => {
            return m.role === 'manager' && m.user.id === currentUserId;
          });
        }
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
      .textContent('This will delete the project permanently from the hub.')
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

  function shouldShowActionsMenu(membership) {
    // This method determines whether the `Actions` button and menu gets shown –
    // so it must represent the ORed logic of all the conditions used for the
    // menu buttons, i.e. determine if at least one button will be shown.

    return ctrl.isAdmin || ctrl.isProjectManager || allowOnboardOrOffboardGitHub(membership);
  }

  function addMembership() {
    if (!ctrl.isAdmin && !ctrl.isProjectManager) {
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
    if (!ctrl.isAdmin && !ctrl.isProjectManager) {
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

  function allowOnboardOrOffboardGitHub(membership) {
    return (
      (ctrl.isAdmin || ctrl.isProjectManager) &&
      _.includes(membership.user.enabled_identities, 'github')
    );
  }

  function userOnboardGitHub(userId, targetEvent) {
    if (!ctrl.isAdmin && !ctrl.isProjectManager) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will onboard the user on to the GitHub organisation and main GitHub team. Only continue if you have confirmed that the user has a) 2FA set up, and b) a full name, on their GitHub account.')
      .ariaLabel('Confirm onboarding of user on to GitHub.')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processing = true;

        hubApiService
          .userOnboardGitHub(userId)
          .then(() => {
            logger.success('User should receive an invite to join the org and team, or has already been added');
          })
          .finally(() => {
            ctrl.processing = false;
          });
      });
  }

  function userOffboardGitHub(userId, targetEvent) {
    if (!ctrl.isAdmin && !ctrl.isProjectManager) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will offboard the user from GitHub - removing them from the GitHub org and associated teams. Continue with caution as this will remove their access from repositories, etc.')
      .ariaLabel('Confirm offboarding of user from GitHub.')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processing = true;

        hubApiService
          .userOffboardGitHub(userId)
          .then(() => {
            logger.success('User should now be removed from the GitHub org and associated teams');
          })
          .finally(() => {
            ctrl.processing = false;
          });
      });
  }
}
