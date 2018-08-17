export const DocsSourcesListComponent = {
  template: require('./docs-sources-list.html'),
  controller: DocsSourcesListController
};

function DocsSourcesListController(DocsSources) {
  'ngInject';

  const ctrl = this;

  ctrl.DocsSources = DocsSources;

  ctrl.sources = [];

  ctrl.loading = false;

  init();

  function init() {
    ctrl.loading = true;

    DocsSources
      .getAll()
      .then(sources => {
        ctrl.sources = sources;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
