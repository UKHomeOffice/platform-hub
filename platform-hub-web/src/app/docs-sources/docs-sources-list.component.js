export const DocsSourcesListComponent = {
  template: require('./docs-sources-list.html'),
  controller: DocsSourcesListController
};

function DocsSourcesListController(DocsSources, FeatureFlags, featureFlagKeys, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.DocsSources = DocsSources;
  ctrl.FeatureFlags = FeatureFlags;
  ctrl.featureFlagKeys = featureFlagKeys;

  ctrl.sources = [];

  ctrl.loading = false;

  init();

  ctrl.triggerSyncAll = triggerSyncAll;
  ctrl.triggerSync = triggerSync;

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

  function triggerSyncAll() {
    DocsSources
      .syncAll()
      .then(() => {
        logger.success('A background job has been triggered to sync all docs sources. Sit back and relax.');
      });
  }

  function triggerSync(docsSource) {
    DocsSources
      .sync(docsSource.id)
      .then(() => {
        logger.success('A background job has been triggered to sync that particular docs source. Sit back and relax.');
      });
  }
}
