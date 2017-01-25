export const events = function () {
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
