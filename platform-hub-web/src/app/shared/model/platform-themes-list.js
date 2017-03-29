import angular from 'angular';

export const PlatformThemesList = function ($window, $q, AppSettings, apiBackoffTimeMs, hubApiService, arrayUtilsService, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.all = [];
  model.visible = [];
  model.hidden = [];

  model.refresh = refresh;

  return model;

  function refresh() {
    if (_.isNull(fetcherPromise)) {
      const themesPromise = hubApiService.getPlatformThemes();
      const settingsPromise = AppSettings.refresh();

      fetcherPromise = $q.all([
        themesPromise,
        settingsPromise
      ]).then(results => {
        buildLists(results[0], AppSettings.data.visiblePlatformThemes || []);
        return model.all;
      }).finally(() => {
        // Reuse the same promise for some time, to prevent smashing the API
        $window.setTimeout(() => {
          fetcherPromise = null;
        }, apiBackoffTimeMs);
      });
    }
    return fetcherPromise;
  }

  function buildLists(themes, visibleIds) {
    // IMPORTANT: we need to ensure two things for the visible list
    // 1. The ordering is the same as the visibleIds provided
    // 2. We need to take into account entries in visibleIds that may not exist anymore

    angular.copy(themes, model.all);

    const [left, right] = arrayUtilsService.splitBySortedIds(themes, visibleIds);
    angular.copy(left, model.visible);
    angular.copy(right, model.hidden);
  }
};
