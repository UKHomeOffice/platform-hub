export const ContactListFormComponent = {
  template: require('./contact-list-form.html'),
  controller: ContactListFormController
};

function ContactListFormController($q, ContactLists, logger, _) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.lists = [];
  ctrl.listIds = _.keys(ctrl.lists);

  ctrl.update = update;

  init();

  function init() {
    ctrl.loading = true;

    ContactLists
      .all()
      .then(results => {
        ctrl.lists = results.reduce((acc, cl) => {
          acc.push({
            id: cl.id,
            emailAddressesString: cl.email_addresses.join('\n')
          });
          return acc;
        }, []);
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function update() {
    ctrl.saving = true;

    const promises = ctrl.lists.map(cl => {
      const emailAddresses = _.filter(cl.emailAddressesString.split('\n'));
      return ContactLists.update(cl.id, emailAddresses);
    });

    $q
      .all(promises)
      .then(() => {
        logger.success('Contact lists updated');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
