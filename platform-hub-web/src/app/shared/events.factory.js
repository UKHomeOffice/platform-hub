export const events = function () {
  'ngInject';

  return {
    api: {
      resourceNotFound: 'api:resourceNotFound'
    },
    auth: {
      deactivated: 'auth:deactivated',
      forbidden: 'auth:forbidden',
      unauthorized: 'auth:unauthorized',
      updated: 'auth:updated'
    }
  };
};
