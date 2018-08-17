export const DocsSourcesFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./docs-sources-form.html'),
  controller: DocsSourcesFormController
};

function DocsSourcesFormController($state, DocsSources, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.DocsSources = DocsSources;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.source = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.source = initEmptySource();
      ctrl.loading = false;
    } else {
      loadSource();
    }
  }

  function initEmptySource() {
    return {
      config: {}
    };
  }

  function loadSource() {
    ctrl.loading = true;
    ctrl.source = null;

    DocsSources
      .get(id)
      .then(source => {
        ctrl.source = source;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.sourceForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    if (ctrl.isNew) {
      DocsSources
        .create(ctrl.source)
        .then(source => {
          logger.success('New docs source created');
          $state.go('docs-sources.detail', {id: source.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      DocsSources
        .update(ctrl.source.id, ctrl.source)
        .then(source => {
          logger.success('Docs source updated');
          $state.go('docs-sources.detail', {id: source.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }
}
