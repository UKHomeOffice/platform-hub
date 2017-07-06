import angular from 'angular';

export const FeatureFlags = function ($window, hubApiService, apiBackoffTimeMs, logger, featureFlagKeys, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  const data = {};

  model.refresh = refresh;
  model.clear = clear;
  model.isEnabled = isEnabled;

  return model;

  function refresh(force) {
    if (force || _.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getFeatureFlags()
        .then(flags => {
          angular.copy(flags, data);
          return data;
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
    angular.copy({}, data);
  }

  function isEnabled(featureKey) {
    if (_.includes(featureFlagKeys, featureKey)) {
      return data[featureKey] || false;
    }
    return false;
  }
};
