export const QaEntriesDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./qa-entries-detail.html'),
  controller: QaEntriesDetailController
};

function QaEntriesDetailController($mdDialog, $state, QaEntries, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.QaEntries = QaEntries;

  ctrl.loading = true;
  ctrl.entry = null;

  ctrl.deleteEntry = deleteEntry;

  init();

  function init() {
    loadEntry();
  }

  function loadEntry() {
    ctrl.loading = true;
    ctrl.entry = null;

    QaEntries
      .get(id)
      .then(entry => {
        ctrl.entry = entry;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function deleteEntry(targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the Q&A entry permanently from the hub.')
      .ariaLabel('Confirm deletion of Q&A entry')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        QaEntries
          .delete(ctrl.entry.id)
          .then(() => {
            logger.success('Q&A entry deleted');
            $state.go('qa-entries.list');
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }
}
