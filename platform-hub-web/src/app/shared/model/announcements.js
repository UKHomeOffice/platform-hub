/* eslint camelcase: 0 */

import angular from 'angular';

export const Announcements = function ($timeout, moment, apiBackoffTimeMs, hubApiService, _) {
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
  model.isPublished = isPublished;
  model.publishNow = publishNow;
  model.markSticky = markSticky;
  model.unmarkSticky = unmarkSticky;
  model.resend = resend;
  model.hasDeliveryTargets = hasDeliveryTargets;
  model.createAnnouncement = createAnnouncement;
  model.updateAnnouncement = updateAnnouncement;
  model.deleteAnnouncement = deleteAnnouncement;

  return model;

  function refreshGlobal(force) {
    if (force || _.isNull(globalFetcherPromise)) {
      globalFetcherPromise = hubApiService
        .getGlobalAnnouncements()
        .then(results => {
          const announcements = processAnnouncementsFromApi(results);
          angular.copy(announcements, model.global);
          angular.copy(_.filter(announcements, 'is_sticky'), model.sticky);
          return announcements;
        }).finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $timeout(() => {
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
          $timeout(() => {
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

    return !model.isPublished(announcement);
  }

  function isPublished(announcement) {
    return moment(announcement.publish_at).isSameOrBefore(moment());
  }

  function publishNow(announcement) {
    announcement.publish_at = moment.utc().format();
    return hubApiService
      .updateAnnouncement(announcement.id, announcement)
      .then(() => {
        return refreshGlobal(true);
      });
  }

  function markSticky(announcement) {
    return hubApiService
      .announcementMarkSticky(announcement.id)
      .then(() => {
        return refreshGlobal(true);
      });
  }

  function unmarkSticky(announcement) {
    return hubApiService
      .announcementUnmarkSticky(announcement.id)
      .then(() => {
        return refreshGlobal(true);
      });
  }

  function resend(announcement) {
    return hubApiService
      .announcementResend(announcement.id)
      .then(() => {
        return refreshGlobal(true);
      });
  }

  function hasDeliveryTargets(announcement) {
    const d = announcement.deliver_to;
    return d && !_.isEmpty(d) && (
      (d.hub_users && !_.isEmpty(d.hub_users)) ||
      (d.contact_lists && !_.isEmpty(d.contact_lists)) ||
      (d.slack_channels && !_.isEmpty(d.slack_channels))
    );
  }

  function createAnnouncement(data) {
    return hubApiService
      .createAnnouncement(data)
      .then(announcement => {
        return refreshGlobal(true)
          .then(() => {
            return announcement;
          });
      });
  }

  function updateAnnouncement(id, data) {
    return hubApiService
      .updateAnnouncement(id, data)
      .then(announcement => {
        return refreshGlobal(true)
          .then(() => {
            return announcement;
          });
      });
  }

  function deleteAnnouncement(announcement) {
    return hubApiService
      .deleteAnnouncement(announcement.id)
      .then(() => {
        return refreshGlobal(true);
      });
  }

  function processAnnouncementsFromApi(results) {
    return results.map(a => {
      a.colour = model.coloursForLevel[a.level];
      return a;
    });
  }
};
