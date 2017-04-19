import angular from 'angular';

export const Me = function ($window, windowPopupService, hubApiService, homeEndpoint, apiBackoffTimeMs, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.data = {};

  model.refresh = refresh;
  model.clear = clear;
  model.connectIdentity = connectIdentity;
  model.deleteIdentity = deleteIdentity;

  return model;

  function refresh(force) {
    if (force || _.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getMe()
        .then(me => {
          angular.copy(me, model.data);
          return model.data;
        })
        .finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $window.setTimeout(() => {
            fetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return fetcherPromise;
  }

  function clear() {
    angular.copy({}, model.data);
  }

  function connectIdentity(provider) {
    return windowPopupService.open(
      hubApiService.getIdentityFlowStartEndpoint(provider),
      `${provider}IdentityFlowPopup`,
      {},
      homeEndpoint
    ).then(() => {
      return refresh(true);
    });
  }

  function deleteIdentity(provider) {
    return hubApiService
      .deleteMeIdentity(provider)
      .then(() => {
        return refresh(true);
      });
  }
};
