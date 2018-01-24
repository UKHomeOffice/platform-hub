/* eslint camelcase: 0 */

export const UsersListComponent = {
  template: require('./users-list.html'),
  controller: UsersListController
};

function UsersListController($mdDialog, hubApiService, Me, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.users = [];

  ctrl.fetchUsers = fetchUsers;
  ctrl.toggleAdmin = toggleAdmin;
  ctrl.toggleLimitedAdmin = toggleLimitedAdmin;
  ctrl.activateUser = activateUser;
  ctrl.deactivateUser = deactivateUser;
  ctrl.isCurrentUser = isCurrentUser;

  init();

  function init() {
    fetchUsers();
  }

  function fetchUsers(page = 1) {
    ctrl.loading = true;

    return hubApiService
      .getUsers(page)
      .then(users => {
        ctrl.users = users;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function toggleAdmin(user, targetEvent) {
    let promptMessage = 'This will make the user a hub admin and give them privileged access to all parts of the hub – DO THIS WITH CAUTION PLEASE.';
    if (user.role === 'admin') {
      promptMessage = 'This will remove hub admin privileges for the user.';
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent(promptMessage)
      .ariaLabel('Confirm admin role toggle')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    ctrl.saving = true;

    return $mdDialog
      .show(confirm)
      .then(() => {
        if (user.role === 'admin') {
          return hubApiService
            .revokeAdmin(user.id)
            .then(() => {
              user.role = null;
              logger.success('Revoked hub admin role');
            });
        }

        return hubApiService
          .makeAdmin(user.id)
          .then(() => {
            user.role = 'admin';
            logger.success('Made the user a hub admin');
          });
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function toggleLimitedAdmin(user, targetEvent) {
    let promptMessage = 'This will make the user a limited hub admin and give them some privileged access to the hub.';
    if (user.role === 'limited_admin') {
      promptMessage = 'This will remove limited hub admin privileges for the user.';
    }

    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent(promptMessage)
      .ariaLabel('Confirm limited admin role toggle')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    ctrl.saving = true;

    return $mdDialog
      .show(confirm)
      .then(() => {
        if (user.role === 'limited_admin') {
          return hubApiService
            .revokeLimitedAdmin(user.id)
            .then(() => {
              user.role = null;
              logger.success('Revoked hub limited admin role');
            });
        }

        return hubApiService
          .makeLimitedAdmin(user.id)
          .then(() => {
            user.role = 'limited_admin';
            logger.success('Made the user a hub limited admin');
          });
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function activateUser(user) {
    ctrl.saving = true;

    hubApiService
      .activateUser(user.id)
      .then(() => {
        user.is_active = true;
        logger.success('User activated');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function deactivateUser(user) {
    ctrl.saving = true;

    hubApiService
      .deactivateUser(user.id)
      .then(() => {
        user.is_active = false;
        logger.success('User deactivated');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function isCurrentUser(user) {
    return Me.data.id === user.id;
  }
}
