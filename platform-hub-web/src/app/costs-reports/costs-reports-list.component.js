export const CostsReportsListComponent = {
  template: require('./costs-reports-list.html'),
  controller: CostsReportsListController
};

function CostsReportsListController(CostsReports) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.reports = [];

  init();

  function init() {
    fetchReports();
  }

  function fetchReports() {
    ctrl.loading = true;

    return CostsReports
      .getAll()
      .then(reports => {
        ctrl.reports = reports;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
