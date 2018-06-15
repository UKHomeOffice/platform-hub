export const ProjectsDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./projects-detail.html'),
  controller: ProjectsDetailController
};

function ProjectsDetailController($rootScope, $q, $mdDialog, $state, roleCheckerService, hubApiService, FeatureFlags, featureFlagKeys, Me, Projects, logger, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.FeatureFlags = FeatureFlags;
  ctrl.featureFlagKeys = featureFlagKeys;

  ctrl.loading = true;
  ctrl.isAdmin = false;
  ctrl.isProjectTeamMember = false;
  ctrl.isProjectAdmin = false;
  ctrl.project = null;
  ctrl.memberships = [];
  ctrl.searchSelectedUser = null;
  ctrl.searchText = '';
  ctrl.processing = false;
  ctrl.services = [];
  ctrl.loadingServices = false;
  ctrl.kubernetesUserTokens = [];
  ctrl.kubernetesUserTokensSelectedUser = undefined;
  ctrl.processingKubernetesUserTokens = false;
  ctrl.bills = [];
  ctrl.loadingBills = false;
  ctrl.billsExpanded = false;

  ctrl.deleteProject = deleteProject;
  ctrl.searchUsers = searchUsers;
  ctrl.shouldShowActionsMenu = shouldShowActionsMenu;
  ctrl.addMembership = addMembership;
  ctrl.removeMembership = removeMembership;
  ctrl.makeAdmin = makeAdmin;
  ctrl.demoteAdmin = demoteAdmin;
  ctrl.allowOnboardOrOffboardGitHub = allowOnboardOrOffboardGitHub;
  ctrl.userOnboardGitHub = userOnboardGitHub;
  ctrl.userOffboardGitHub = userOffboardGitHub;
  ctrl.offboardAndRemove = offboardAndRemove;
  ctrl.shouldShowServicesTab = shouldShowServicesTab;
  ctrl.loadServices = loadServices;
  ctrl.shouldShowCreateServiceButton = shouldShowCreateServiceButton;
  ctrl.loadKubernetesUserTokens = loadKubernetesUserTokens;
  ctrl.shouldShowBillsTab = shouldShowBillsTab;
  ctrl.loadBills = loadBills;

  init();

  function init() {
    loadAdminStatus()
      .then(loadProject);
  }

  function loadAdminStatus() {
    return roleCheckerService
      .hasHubRole('admin')
      .then(hasRole => {
        ctrl.isAdmin = hasRole;
      });
  }

  function loadProject() {
    ctrl.loading = true;
    ctrl.isProjectAdmin = false;
    ctrl.project = null;
    ctrl.memberships = [];
    ctrl.searchSelectedUser = null;
    ctrl.searchText = '';

    const projectFetch = Projects
      .get(id)
      .then(project => {
        ctrl.project = project;
      });

    const membershipsFetch = Projects
      .getMemberships(id)
      .then(memberships => {
        ctrl.memberships = memberships;

        // We expect at this point that the Me resource has definitely been fetched!
        const currentUserId = Me.data.id;
        if (currentUserId) {
          ctrl.isProjectTeamMember = _.some(memberships, m => {
            return m.user.id === currentUserId;
          });
        }
      });

    const adminCheck = Projects
      .membershipRoleCheck(id, 'admin')
      .then(data => {
        ctrl.isProjectAdmin = data.result;
      });

    return $q
      .all([projectFetch, membershipsFetch, adminCheck])
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function deleteProject(targetEvent) {
    if (!ctrl.isAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the project (and all it\'s memberships and services) permanently from the hub.')
      .ariaLabel('Confirm deletion of project')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        Projects
          .delete(ctrl.project.id)
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

    return ctrl.isAdmin || ctrl.isProjectAdmin || allowOnboardOrOffboardGitHub(membership);
  }

  function addMembership() {
    if (!ctrl.isAdmin && !ctrl.isProjectAdmin) {
      return;
    }

    Projects
      .addMembership(ctrl.project.id, ctrl.searchSelectedUser.id)
      .then(() => {
        logger.success('Team member added to project');
        loadProject();
      });
  }

  function removeMembership(membership, targetEvent) {
    if (!ctrl.isAdmin && !ctrl.isProjectAdmin) {
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

        Projects
          .removeMembership(ctrl.project.id, membership.user.id)
          .then(() => {
            logger.success('Team member removed from project');
            loadProject();
          });
      });
  }

  function makeAdmin(membership, targetEvent) {
    if (!ctrl.isAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will make this person an admin of the project (giving them certain privileges).')
      .ariaLabel('Confirm making this person a project admin.')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        Projects
          .setMembershipRole(ctrl.project.id, membership.user.id, 'admin')
          .then(() => {
            logger.success('Team member promoted to admin!');
            loadProject();
          });
      });
  }

  function demoteAdmin(membership, targetEvent) {
    if (!ctrl.isAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will demote this person from their admin role in the project (though they will still be a member of the project).')
      .ariaLabel('Confirm demotion of a project admin.')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        Projects
          .unsetMembershipRole(ctrl.project.id, membership.user.id, 'admin')
          .then(() => {
            logger.success('Team member demoted from admin role!');
            loadProject();
          });
      });
  }

  function allowOnboardOrOffboardGitHub(membership) {
    return (
      (ctrl.isAdmin || ctrl.isProjectAdmin) &&
      _.includes(membership.user.enabled_identities, 'github')
    );
  }

  function userOnboardGitHub(userId, targetEvent) {
    if (!ctrl.isAdmin && !ctrl.isProjectAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will onboard the user on to the GitHub org and main GitHub team. Only continue if you have confirmed that the user has a) 2FA set up, and b) a full name, on their GitHub account.')
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
    if (!ctrl.isAdmin && !ctrl.isProjectAdmin) {
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

  function offboardAndRemove(membership, targetEvent) {
    if (!ctrl.isAdmin && !ctrl.isProjectAdmin) {
      return;
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will remove the person from the GitHub org as well as this team. Continue with caution as this will remove their access from repositories, etc.')
      .ariaLabel('Confirm offboarding from GitHub and removal of team member from project')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        Projects
          .removeMembership(ctrl.project.id, membership.user.id)
          .then(() => {
            ctrl.processing = true;

            hubApiService
              .userOffboardGitHub(membership.user.id)
              .then(() => {
                logger.success('User should now be removed from the GitHub org (and associated teams) and from the project team');
                loadProject();
              })
              .finally(() => {
                ctrl.processing = false;
              });
          });
      });
  }

  function shouldShowServicesTab() {
    return ctrl.isAdmin || ctrl.isProjectTeamMember;
  }

  function loadServices() {
    ctrl.loadingServices = true;

    Projects
      .getServices(ctrl.project.id)
      .then(services => {
        angular.copy(services, ctrl.services);
      }).finally(() => {
        ctrl.loadingServices = false;
      });
  }

  function shouldShowCreateServiceButton() {
    return ctrl.isAdmin || ctrl.isProjectAdmin;
  }

  function loadKubernetesUserTokens() {
    ctrl.processingKubernetesUserTokens = true;
    ctrl.kubernetesUserTokens = [];

    Projects
      .getKubernetesUserTokens(ctrl.project.id)
      .then(tokens => {
        angular.copy(tokens, ctrl.kubernetesUserTokens);
      })
      .finally(() => {
        ctrl.processingKubernetesUserTokens = false;
      });
  }

  function shouldShowBillsTab() {
    return ctrl.isAdmin || ctrl.isProjectAdmin;
  }

  function loadBills() {
    ctrl.loadingBills = true;
    ctrl.bills = [];

    Projects
      .getBills(ctrl.project.id)
      .then(bills => {
        angular.copy(bills, ctrl.bills);
      })
      .finally(() => {
        ctrl.loadingBills = false;
      });
  }
}
