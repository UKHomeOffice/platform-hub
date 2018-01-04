export const ProjectBillBreakdownTableComponent = {
  bindings: {
    totals: '<',
    services: '<'
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
    const clusters = _.keys(ctrl.totals.clusters);

    const headers = [''].concat(clusters).concat(['Shared services']);

    const totalsRow = ['Total']
      .concat(clusters.map(c => ctrl.totals.clusters[c]))
      .concat([ctrl.totals.shared_services]);

    const serviceRows = _.values(ctrl.services).map(s => {
      return [`Service: ${s.name}`]
        .concat(clusters.map(c => s.totals.clusters[c]))
        .concat([s.totals.shared_services]);
    });

    const rows = [totalsRow].concat(serviceRows);

    ctrl.headers = headers;
    ctrl.rows = rows;
  }
}
