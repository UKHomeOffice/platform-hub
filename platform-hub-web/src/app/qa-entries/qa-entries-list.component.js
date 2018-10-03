export const QaEntriesListComponent = {
  template: require('./qa-entries-list.html'),
  controller: QaEntriesListController
};

function QaEntriesListController(QaEntries) {
  'ngInject';

  const ctrl = this;

  ctrl.QaEntries = QaEntries;

  ctrl.entries = [];

  ctrl.loading = false;

  init();

  function init() {
    ctrl.loading = true;

    QaEntries
      .getAll()
      .then(entries => {
        ctrl.entries = entries;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
