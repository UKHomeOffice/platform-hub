/* eslint camelcase: 0 */

export const UsersListComponent = {
  template: require('./users-list.html'),
  controller: UsersListController
};

function UsersListController(hubApiService, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.users = [];

  ctrl.makeAdmin = makeAdmin;
  ctrl.revokeAdmin = revokeAdmin;
  ctrl.activateUser = activateUser;
  ctrl.deactivateUser = deactivateUser;

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

  function makeAdmin(user) {
    hubApiService
      .makeAdmin(user.id)
      .then(() => {
        user.role = 'admin';
        logger.success('Made a new admin');
      });
  }

  function revokeAdmin(user) {
    hubApiService
      .revokeAdmin(user.id)
      .then(() => {
        user.role = null;
        logger.success('Removed an admin');
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
}
