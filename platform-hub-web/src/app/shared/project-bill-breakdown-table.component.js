export const ProjectBillBreakdownTableComponent = {
  bindings: {
    bills: '<'
  },
  template: require('./project-bill-breakdown-table.html'),
  controller: ProjectBillBreakdownTableController
};

function ProjectBillBreakdownTableController(_) {
  'ngInject';

  const ctrl = this;

  ctrl.headers = [];
  ctrl.rows = [];

  init();

  function init() {
    const totals = {
      total: 0.0,
      resources: 0.0,
      clusterGroups: {},
      shared: 0.0
    };

    const clusterGroupNames = new Set();

    const serviceSummaries = [];

    _.each(ctrl.bills.services, s => {
      const summary = {
        label: `Service: ${s.name}`,
        total: 0.0,
        resources: 0.0,
        clusterGroups: {},
        shared: 0.0
      };

      // Resources

      const knownResourcesAmount = s.known_resources || 0.0;
      summary.resources += knownResourcesAmount;
      totals.resources += knownResourcesAmount;
      summary.total += knownResourcesAmount;
      totals.total += knownResourcesAmount;

      // Cluster groups

      _.each(s.cluster_groups, (entries, name) => {
        clusterGroupNames.add(name);

        if (!_.has(summary.clusterGroups, name)) {
          summary.clusterGroups[name] = 0.0;
        }
        if (!_.has(totals.clusterGroups, name)) {
          totals.clusterGroups[name] = 0.0;
        }

        const clusterGroupAmount = _.sum(_.values(entries));
        summary.clusterGroups[name] += clusterGroupAmount;
        totals.clusterGroups[name] += clusterGroupAmount;
        summary.total += clusterGroupAmount;
        totals.total += clusterGroupAmount;
      });

      // Shared

      const fromUnknownSharedAmount = s.shared.from_unknown || 0.0;
      summary.shared += fromUnknownSharedAmount;
      totals.shared += fromUnknownSharedAmount;
      summary.total += fromUnknownSharedAmount;
      totals.total += fromUnknownSharedAmount;

      const fromUnmappedSharedAmount = s.shared.from_unmapped || 0.0;
      summary.shared += fromUnmappedSharedAmount;
      totals.shared += fromUnmappedSharedAmount;
      summary.total += fromUnmappedSharedAmount;
      totals.total += fromUnmappedSharedAmount;

      const fromSharedClustersAmount = _.sum(_.values(s.shared.from_shared_clusters));
      summary.shared += fromSharedClustersAmount;
      totals.shared += fromSharedClustersAmount;
      summary.total += fromSharedClustersAmount;
      totals.total += fromSharedClustersAmount;

      _.each(s.shared.from_shared_projects, sharedProject => {
        const topLevelKnownResourcesAmount = _.get(sharedProject, 'top_level.known_resources') || 0.0;
        summary.shared += topLevelKnownResourcesAmount;
        totals.shared += topLevelKnownResourcesAmount;
        summary.total += topLevelKnownResourcesAmount;
        totals.total += topLevelKnownResourcesAmount;

        _.each(sharedProject.services, sharedService => {
          const sharedServiceKnownResourcesAmount = sharedService.known_resources || 0.0;
          summary.shared += sharedServiceKnownResourcesAmount;
          totals.shared += sharedServiceKnownResourcesAmount;
          summary.total += sharedServiceKnownResourcesAmount;
          totals.total += sharedServiceKnownResourcesAmount;

          _.each(sharedService.cluster_groups, amount => {
            summary.shared += amount;
            totals.shared += amount;
            summary.total += amount;
            totals.total += amount;
          });
        });
      });

      serviceSummaries.push(summary);
    });

    const clusterGroupNamesSorted = Array.from(clusterGroupNames).sort();

    const headers = [
      '',
      'Total',
      'Resources'
    ].concat(clusterGroupNamesSorted)
     .concat(['Platform / Shared']);

    const serviceSummariesSorted = _.sortBy(serviceSummaries, ['label']);
    const serviceRows = serviceSummariesSorted.map(s => {
      return [
        s.label,
        s.total,
        s.resources
      ].concat(clusterGroupNamesSorted.map(b => s.clusterGroups[b] || 0.0))
       .concat([s.shared]);
    });

    const topLevelKnownResourcesAmount = _.get(ctrl.bills, 'top_level.known_resources') || 0.0;
    totals.resources += topLevelKnownResourcesAmount;
    totals.total += topLevelKnownResourcesAmount;
    const topLevelRow = [
      'Top level',
      topLevelKnownResourcesAmount,
      topLevelKnownResourcesAmount
    ].concat(clusterGroupNamesSorted.map(() => '--'))
     .concat(['--']);

    const totalsRow = [
      'Total',
      totals.total,
      totals.resources
    ].concat(clusterGroupNamesSorted.map(b => totals.clusterGroups[b] || 0.0))
     .concat([totals.shared]);

    const rows = [totalsRow, topLevelRow].concat(serviceRows);

    ctrl.headers = headers;
    ctrl.rows = rows;
  }
}
