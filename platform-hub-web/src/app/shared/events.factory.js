export const events = function () {
  'ngInject';

  return {
    auth: {
      updated: 'auth:updated',
      unauthorized: 'auth:unauthorized',
      forbidden: 'auth:forbidden',
      deactivated: 'auth:deactivated'
    }
  };
};
