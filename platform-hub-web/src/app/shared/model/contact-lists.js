/* eslint camelcase: 0 */

export const ContactLists = function ($q, hubApiService) {
  'ngInject';

  const listIds = [
    'global'
  ];

  const model = {};

  model.all = all;
  model.update = update;

  return model;

  function all() {
    const promises = listIds.map(hubApiService.getContactList);
    return $q.all(promises);
  }

  function update(id, emailAddresses) {
    return hubApiService.updateContactList(id, {
      email_addresses: emailAddresses
    });
  }
};
