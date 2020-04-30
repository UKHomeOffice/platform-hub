import angular from 'angular';

export const AnnouncementTemplates = function ($timeout, apiBackoffTimeMs, hubApiService, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.all = [];

  model.refresh = refresh;
  model.lookup = lookup;

  return model;

  function refresh() {
    if (_.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getAnnouncementTemplates()
        .then(templates => {
          angular.copy(templates, model.all);
          return model.all;
        })
        .finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $timeout(() => {
            fetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return fetcherPromise;
  }

  function lookup(id) {
    return _.find(model.all, ['id', id]);
  }
};
