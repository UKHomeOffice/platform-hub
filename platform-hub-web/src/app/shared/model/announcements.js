import angular from 'angular';

export const Announcements = function ($window, moment, apiBackoffTimeMs, hubApiService, _) {
  'ngInject';

  const model = {};

  let globalFetcherPromise = null;
  let allFetcherPromise = null;

  model.levels = [
    'info',
    'warning',
    'critical'
  ];

  model.coloursForLevel = {
    info: 'green',
    warning: 'amber',
    critical: 'red'
  };

  model.global = [];
  model.sticky = [];
  model.all = [];

  model.refreshGlobal = refreshGlobal;
  model.refreshAll = refreshAll;
  model.isEditable = isEditable;

  return model;

  function refreshGlobal() {
    if (_.isNull(globalFetcherPromise)) {
      globalFetcherPromise = hubApiService
        .getGlobalAnnouncements()
        .then(results => {
          const announcements = processAnnouncementsFromApi(results);
          angular.copy(announcements, model.global);
          angular.copy(_.filter(announcements, 'is_sticky'), model.sticky);
          return announcements;
        }).finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $window.setTimeout(() => {
            globalFetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return globalFetcherPromise;
  }

  function refreshAll() {
    if (_.isNull(allFetcherPromise)) {
      allFetcherPromise = hubApiService
        .getAllAnnouncements()
        .then(results => {
          const announcements = processAnnouncementsFromApi(results);
          angular.copy(announcements, model.all);
          return announcements;
        }).finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $window.setTimeout(() => {
            allFetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return allFetcherPromise;
  }

  function isEditable(announcement) {
    if (_.isNull(announcement)) {
      return false;
    }

    if (announcement.status !== 'awaiting_delivery') {
      return false;
    }

    return moment(announcement.publish_at).isAfter(moment());
  }

  function processAnnouncementsFromApi(results) {
    return results.map(a => {
      a.colour = model.coloursForLevel[a.level];
      return a;
    });
  }
};
