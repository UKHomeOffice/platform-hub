/* eslint camelcase: 0 */

export const UsersListComponent = {
  template: require('./users-list.html'),
  controller: UsersListController
};

function UsersListController(hubApiService, Me, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.users = [];

  ctrl.toggleAdmin = toggleAdmin;
  ctrl.toggleLimitedAdmin = toggleLimitedAdmin;
  ctrl.activateUser = activateUser;
  ctrl.deactivateUser = deactivateUser;
  ctrl.isCurrentUser = isCurrentUser;

  init();

  function init() {
    loadUsers();
  }

  function loadUsers() {
    ctrl.loading = true;
    ctrl.users = [];

    hubApiService
      .getUsers()
      .then(users => {
        ctrl.users = users;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function toggleAdmin(user) {
    if (user.role === 'admin') {
      hubApiService
        .revokeAdmin(user.id)
        .then(() => {
          user.role = null;
          logger.success('Revoked hub admin role');
        });
    } else {
      hubApiService
        .makeAdmin(user.id)
        .then(() => {
          user.role = 'admin';
          logger.success('Made the user a hub admin');
        });
    }
  }

  function toggleLimitedAdmin(user) {
    if (user.role === 'limited_admin') {
      hubApiService
        .revokeLimitedAdmin(user.id)
        .then(() => {
          user.role = null;
          logger.success('Revoked hub limited admin role');
        });
    } else {
      hubApiService
        .makeLimitedAdmin(user.id)
        .then(() => {
          user.role = 'limited_admin';
          logger.success('Made the user a hub limited admin');
        });
    }
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
