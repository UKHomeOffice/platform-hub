export const QaEntriesFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./qa-entries-form.html'),
  controller: QaEntriesFormController
};

function QaEntriesFormController($state, QaEntries, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.QaEntries = QaEntries;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.entry = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.entry = {};
      ctrl.loading = false;
    } else {
      loadEntry();
    }
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

  function createOrUpdate() {
    if (ctrl.entryForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      QaEntries
        .create(ctrl.entry)
        .then(entry => {
          logger.success('New Q&A entry created');
          $state.go('qa-entries.detail', {id: entry.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      QaEntries
        .update(ctrl.entry.id, ctrl.entry)
        .then(entry => {
          logger.success('Q&A entry updated');
          $state.go('qa-entries.detail', {id: entry.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }
}
