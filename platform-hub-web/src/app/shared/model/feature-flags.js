import angular from 'angular';

export const FeatureFlags = function ($window, hubApiService, apiBackoffTimeMs, logger, featureFlagKeys, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.data = {};

  model.refresh = refresh;
  model.isEnabled = isEnabled;
  model.update = update;

  return model;

  function refresh(force) {
    if (force || _.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getFeatureFlags()
        .then(handleFeatureFlagsResourceFromApi)
        .finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $window.setTimeout(() => {
            fetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return fetcherPromise;
  }

  function isEnabled(featureKey) {
    if (_.includes(featureFlagKeys, featureKey)) {
      return model.data[featureKey] || false;
    }
    return false;
  }

  function update(flag, state) {
    return hubApiService
      .updateFeatureFlag(flag, {state})
      .then(handleFeatureFlagsResourceFromApi);
  }

  function handleFeatureFlagsResourceFromApi(flags) {
    angular.copy(flags, model.data);
  }
};
