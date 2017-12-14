export const CostsReportsListComponent = {
  template: require('./costs-reports-list.html'),
  controller: CostsReportsListController
};

function CostsReportsListController($mdDialog, CostsReports, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.reports = [];

  ctrl.publish = publish;

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

  function publish(report, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent(`This will publish the costs report '${report.id}' to projects and allow them see their bill for that month. It's still possible to delete and recreate this report afterwards, but it is highly advised to not do this.`)
      .ariaLabel('Confirm publishing of costs report')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processing = true;

        CostsReports
          .publish(report.id)
          .then(() => {
            logger.success('Costs report published');
            return fetchReports();
          })
          .finally(() => {
            ctrl.processing = false;
          });
      });
  }
}
