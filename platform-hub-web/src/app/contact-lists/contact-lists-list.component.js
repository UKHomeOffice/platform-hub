export const ContactListsListComponent = {
  template: require('./contact-lists-list.html'),
  controller: ContactListsListController
};

function ContactListsListController($mdDialog, hubApiService, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = false;
  ctrl.lists = [];

  ctrl.deleteList = deleteList;

  init();

  function init() {
    loadContactLists();
  }

  function loadContactLists() {
    ctrl.loading = true;

    hubApiService
      .getContactLists()
      .then(lists => {
        ctrl.lists = lists;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function deleteList(list, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the contact list permanently from the hub.')
      .ariaLabel('Confirm deletion of contact list')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .deleteContactList(list.id)
          .then(() => {
            logger.success('Contact list deleted');
            loadContactLists();
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }
}
