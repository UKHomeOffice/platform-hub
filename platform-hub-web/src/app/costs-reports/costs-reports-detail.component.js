export const CostsReportsDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./costs-reports-detail.html'),
  controller: CostsReportsDetailController
};

function CostsReportsDetailController($mdDialog, $state, CostsReports, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.report = null;

  ctrl.deleteReport = deleteReport;

  init();

  function init() {
    CostsReports
      .get(id)
      .then(report => {
        ctrl.report = report;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function deleteReport(id, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent(`This will delete the costs report '${id}'. You can still recreate it later as long as the source data is still available.`)
      .ariaLabel('Confirm deletion of costs report')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        CostsReports
          .delete(id)
          .then(() => {
            logger.success('Costs report deleted');
            $state.go('costs-reports.list');
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }
}