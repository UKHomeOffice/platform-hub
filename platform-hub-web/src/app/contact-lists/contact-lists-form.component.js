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
    return {
      emailAddressesString: ''
    };
  }

  function loadContactList() {
    ctrl.loading = true;
    ctrl.contactList = null;

    hubApiService
      .getContactList(id)
      .then(contactList => {
        ctrl.contactList = {
          id: contactList.id,
          emailAddressesString: contactList.email_addresses.join('\n')
        };
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

    const data = {
      email_addresses: _.uniq(_.filter(ctrl.contactList.emailAddressesString.split('\n')))
    };

    hubApiService
      .updateContactList(ctrl.contactList.id, data)
      .then(() => {
        logger.success(`Contact list ${ctrl.isNew ? 'created' : 'updated'}`);
        $state.go('contact-lists.list');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
