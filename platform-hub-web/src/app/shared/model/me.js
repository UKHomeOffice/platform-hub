import angular from 'angular';

export const Me = function ($window, windowPopupService, hubApiService, homeEndpoints, apiBackoffTimeMs, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.data = {};

  model.refresh = refresh;
  model.clear = clear;
  model.connectIdentity = connectIdentity;
  model.deleteIdentity = deleteIdentity;
  model.completeHubOnboarding = completeHubOnboarding;
  model.completeServicesOnboarding = completeServicesOnboarding;
  model.agreeTermsOfService = agreeTermsOfService;
  model.globalAnnouncementsMarkAllRead = globalAnnouncementsMarkAllRead;
  model.getKubernetesTokens = hubApiService.getMeKubernetesTokens;

  return model;

  function refresh(force) {
    if (force || _.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getMe()
        .then(handleMeResourceFromApi)
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
      homeEndpoints.home
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

  function completeHubOnboarding(data) {
    return hubApiService
      .completeHubOnboarding(data)
      .then(handleMeResourceFromApi);
  }

  function completeServicesOnboarding() {
    return hubApiService
      .completeServicesOnboarding()
      .then(handleMeResourceFromApi);
  }

  function agreeTermsOfService() {
    return hubApiService
      .agreeTermsOfService()
      .then(handleMeResourceFromApi);
  }

  function globalAnnouncementsMarkAllRead() {
    return hubApiService
      .globalAnnouncementsMarkAllRead()
      .then(handleMeResourceFromApi);
  }

  function handleMeResourceFromApi(me) {
    angular.copy(me, model.data);
    return model.data;
  }
};
