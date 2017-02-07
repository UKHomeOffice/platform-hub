export const events = function () {
  'ngInject';

  return {
    auth: {
      updated: 'auth:updated'
    },
    api: {
      me: {
        updated: 'api:me:updated'
      }
    }
  };
};
