export const UsersListComponent = {
  template: require('./users-list.html'),
  controller: UsersListController
};

function UsersListController(hubApiService, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.users = [];

  ctrl.makeAdmin = makeAdmin;
  ctrl.revokeAdmin = revokeAdmin;

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
}
