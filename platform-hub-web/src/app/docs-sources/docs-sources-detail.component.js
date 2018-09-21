export const DocsSourcesDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./docs-sources-detail.html'),
  controller: DocsSourcesDetailController
};

function DocsSourcesDetailController($mdDialog, $state, DocsSources, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.DocsSources = DocsSources;

  ctrl.loading = true;
  ctrl.source = null;
  ctrl.entries = [];
  ctrl.loadingServices = false;

  ctrl.deleteSource = deleteSource;
  ctrl.loadEntries = loadEntries;

  init();

  function init() {
    loadSource();
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

  function deleteSource(targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the docs source permanently from the hub and no longer index it\'s docs.')
      .ariaLabel('Confirm deletion of docs source')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        DocsSources
          .delete(ctrl.source.id)
          .then(() => {
            logger.success('Docs source deleted');
            $state.go('docs-sources.list');
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }

  function loadEntries() {
    ctrl.loadingEntries = true;

    DocsSources
      .getEntries(ctrl.source.id)
      .then(entries => {
        angular.copy(entries, ctrl.entries);
      }).finally(() => {
        ctrl.loadingEntries = false;
      });
  }
}
