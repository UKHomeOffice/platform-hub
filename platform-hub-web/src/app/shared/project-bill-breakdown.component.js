export const ProjectBillBreakdownComponent = {
  bindings: {
    bills: '<',
    mainSharedServices: '<',
    onTotals: '&'
  },
  template: require('./project-bill-breakdown.html'),
  controller: ProjectBillBreakdownController
};

function ProjectBillBreakdownController(AppSettings, _) {
  'ngInject';

  const ctrl = this;

  ctrl.moreInfoLink = null;
  ctrl.totals = null;
  ctrl.headers = [];
  ctrl.rows = [];
  ctrl.sharedHeaders = [];
  ctrl.sharedRows = [];

  init();

  function init() {
    ctrl.moreInfoLink = _.get(
      AppSettings.getCostsReportsSettings(),
      'more_info'
    );

    // Important:
    // we expect the numbers provided in the `bills` to be in Integer cents
    // (i.e. 100 instead of 1.00 for $1)
    // … so we don't have to worry about floating point arithmetic.

    const totals = {
      total: 0,
      resources: 0,
      clusterGroups: {},
      shared: 0
    };

    const clusterGroupNames = new Set();

    const serviceSummaries = [];
    const serviceSharedAllocations = [];

    ctrl.sharedHeaders.push('');
    ctrl.sharedHeaders.push('Total');

    _.keys(ctrl.bills.services).forEach((id, ix) => {
      const s = ctrl.bills.services[id];

      const label = `Service: ${s.name}`;

      const summary = {
        label,
        total: 0,
        resources: 0,
        clusterGroups: {},
        shared: 0
      };

      const sharedAllocation = {
        label,
        total: 0,
        items: []
      };

      // Resources

      const knownResourcesAmount = s.known_resources || 0;
      summary.resources += knownResourcesAmount;
      totals.resources += knownResourcesAmount;
      summary.total += knownResourcesAmount;
      totals.total += knownResourcesAmount;

      // Cluster groups

      _.each(s.cluster_groups, (entries, name) => {
        clusterGroupNames.add(name);

        if (!_.has(summary.clusterGroups, name)) {
          summary.clusterGroups[name] = 0;
        }
        if (!_.has(totals.clusterGroups, name)) {
          totals.clusterGroups[name] = 0;
        }

        const clusterGroupAmount = _.sum(_.values(entries));
        summary.clusterGroups[name] += clusterGroupAmount;
        totals.clusterGroups[name] += clusterGroupAmount;
        summary.total += clusterGroupAmount;
        totals.total += clusterGroupAmount;
      });

      // Shared

      const fromSharedClustersAmount = _.sum(_.values(s.shared.from_shared_clusters));
      summary.shared += fromSharedClustersAmount;
      totals.shared += fromSharedClustersAmount;
      summary.total += fromSharedClustersAmount;
      totals.total += fromSharedClustersAmount;
      // For shared table:
      if (ix === 0) {
        ctrl.sharedHeaders.push('Shared Clusters');
      }
      sharedAllocation.items.push(fromSharedClustersAmount);

      let allMiscSharedServicesTotal = 0;

      _.each(s.shared.from_shared_projects, sharedProject => {
        const topLevelKnownResourcesAmount = _.get(sharedProject, 'top_level.known_resources') || 0;
        summary.shared += topLevelKnownResourcesAmount;
        totals.shared += topLevelKnownResourcesAmount;
        summary.total += topLevelKnownResourcesAmount;
        totals.total += topLevelKnownResourcesAmount;
        allMiscSharedServicesTotal += topLevelKnownResourcesAmount;

        _.each(sharedProject.services, (sharedService, sharedServiceId) => {
          let sharedServiceTotal = 0;

          const sharedServiceKnownResourcesAmount = sharedService.known_resources || 0;
          summary.shared += sharedServiceKnownResourcesAmount;
          totals.shared += sharedServiceKnownResourcesAmount;
          summary.total += sharedServiceKnownResourcesAmount;
          totals.total += sharedServiceKnownResourcesAmount;
          sharedServiceTotal += sharedServiceKnownResourcesAmount;

          _.each(sharedService.cluster_groups, amount => {
            summary.shared += amount;
            totals.shared += amount;
            summary.total += amount;
            totals.total += amount;
            sharedServiceTotal += amount;
          });

          // For shared table:
          if (_.includes(ctrl.mainSharedServices, sharedServiceId)) {
            if (ix === 0) {
              ctrl.sharedHeaders.push(`${sharedProject.shortname}: ${sharedService.name}`);
            }
            sharedAllocation.items.push(sharedServiceTotal);
          } else {
            allMiscSharedServicesTotal += sharedServiceTotal;
          }
        });
      });

      if (ix === 0) {
        ctrl.sharedHeaders.push('Misc shared services');
      }
      sharedAllocation.items.push(allMiscSharedServicesTotal);

      let sharedUnmappedUnknown = 0;

      const fromUnmappedSharedAmount = s.shared.from_unmapped || 0;
      summary.shared += fromUnmappedSharedAmount;
      totals.shared += fromUnmappedSharedAmount;
      summary.total += fromUnmappedSharedAmount;
      totals.total += fromUnmappedSharedAmount;
      sharedUnmappedUnknown += fromUnmappedSharedAmount;

      const fromMissingMetricsAmount = _.sum(_.values(s.shared.from_missing_metrics));
      summary.shared += fromMissingMetricsAmount;
      totals.shared += fromMissingMetricsAmount;
      summary.total += fromMissingMetricsAmount;
      totals.total += fromMissingMetricsAmount;
      sharedUnmappedUnknown += fromMissingMetricsAmount;

      const fromUnknownSharedAmount = s.shared.from_unknown || 0;
      summary.shared += fromUnknownSharedAmount;
      totals.shared += fromUnknownSharedAmount;
      summary.total += fromUnknownSharedAmount;
      totals.total += fromUnknownSharedAmount;
      sharedUnmappedUnknown += fromUnknownSharedAmount;

      // For shared table:
      if (ix === 0) {
        ctrl.sharedHeaders.push('Unmapped / Unknown');
      }
      sharedAllocation.items.push(sharedUnmappedUnknown);

      sharedAllocation.total = summary.shared;

      serviceSummaries.push(summary);
      serviceSharedAllocations.push(sharedAllocation);
    });

    const clusterGroupNamesSorted = Array.from(clusterGroupNames).sort();

    const headers = [
      '',
      'Total',
      'AWS Resources'
    ].concat(clusterGroupNamesSorted)
     .concat(['Platform / Shared']);

    const serviceSummariesSorted = _.sortBy(serviceSummaries, ['label']);
    const serviceRows = serviceSummariesSorted.map(s => {
      return [
        s.label,
        s.total,
        s.resources
      ].concat(clusterGroupNamesSorted.map(b => s.clusterGroups[b] || 0))
       .concat([s.shared]);
    });

    const topLevelKnownResourcesAmount = _.get(ctrl.bills, 'top_level.known_resources') || 0;
    totals.resources += topLevelKnownResourcesAmount;
    totals.total += topLevelKnownResourcesAmount;
    const topLevelRow = [
      'Misc',
      topLevelKnownResourcesAmount,
      topLevelKnownResourcesAmount
    ].concat(clusterGroupNamesSorted.map(() => '--'))
     .concat(['--']);

    const totalsRow = [
      'Total',
      totals.total,
      totals.resources
    ].concat(clusterGroupNamesSorted.map(b => totals.clusterGroups[b] || 0))
     .concat([totals.shared]);

    const rows = [totalsRow, topLevelRow].concat(serviceRows);

    ctrl.headers = headers;
    ctrl.rows = rows;

    ctrl.totals = totals;

    // Emit totals if needed
    if (ctrl.onTotals) {
      ctrl.onTotals({totals});
    }

    // Shared table rows
    const serviceSharedAllocationsSorted = _.sortBy(serviceSharedAllocations, ['label']);
    ctrl.sharedRows = serviceSharedAllocationsSorted.map(s => {
      return [
        s.label,
        s.total
      ].concat(s.items);
    });
  }
}
