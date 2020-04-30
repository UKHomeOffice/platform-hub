import angular from 'angular';

export const AppSettings = function ($timeout, hubApiService, apiBackoffTimeMs, logger, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.data = {};

  model.refresh = refresh;
  model.update = update;
  model.getAppTitle = getAppTitle;
  model.getPlatformName = getPlatformName;
  model.getPlatformOverviewText = getPlatformOverviewText;
  model.getTermsOfServiceText = getTermsOfServiceText;
  model.getOtherManagedServices = getOtherManagedServices;
  model.getCostsReportsSettings = getCostsReportsSettings;

  return model;

  function refresh() {
    if (_.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getAppSettings()
        .then(settings => {
          angular.copy(settings, model.data);
          return model.data;
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

  function update(data) {
    return hubApiService
      .updateAppSettings(data)
      .then(settings => {
        angular.copy(settings, model.data);
        logger.info('Sucessfully updated app settings');
        return model.data;
      });
  }

  function getAppTitle() {
    return `${getPlatformName()} Hub`;
  }

  function getPlatformName() {
    return model.data.platformName || 'Platform';
  }

  function getPlatformOverviewText() {
    return model.data.platform_overview || '';
  }

  function getTermsOfServiceText() {
    return model.data.terms_of_service_text || '';
  }

  function getOtherManagedServices() {
    return model.data.other_managed_services || [];
  }

  function getCostsReportsSettings() {
    return model.data.costs_reports || {};
  }
};
