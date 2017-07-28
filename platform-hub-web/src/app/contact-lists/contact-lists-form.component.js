/* eslint camelcase: 0 */

export const ContactListsFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./contact-lists-form.html'),
  controller: ContactListsFormController
};

function ContactListsFormController($state, hubApiService, logger, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.fieldIdRegex = '^[a-zA-Z][\\w-]*$';

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.contactList = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.contactList = initEmptyContactList();
      ctrl.loading = false;
    } else {
      loadContactList();
    }
  }

  function initEmptyContactList() {
    return {};
  }

  function loadContactList() {
    ctrl.loading = true;
    ctrl.contactList = null;

    hubApiService
      .getContactList(id)
      .then(contactList => {
        ctrl.contactList = contactList;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.contactListForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    ctrl.contactList.email_addresses =
      _.uniq(
        _.map(
          ctrl.contactList.email_addresses,
          _.trim
        )
      );

    hubApiService
      .updateContactList(ctrl.contactList.id, ctrl.contactList)
      .then(() => {
        logger.success(`Contact list ${ctrl.isNew ? 'created' : 'updated'}`);
        $state.go('contact-lists.list');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
