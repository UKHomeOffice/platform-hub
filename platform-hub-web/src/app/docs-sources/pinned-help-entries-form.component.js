/* eslint camelcase: 0 */

export const PinnedHelpEntriesFormComponent = {
  template: require('./pinned-help-entries-form.html'),
  controller: PinnedHelpEntriesFormController
};

function PinnedHelpEntriesFormController(PinnedHelpEntries, hubApiService, logger, _) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.entries = [];
  ctrl.searchSelectedEntry = null;
  ctrl.searchText = '';

  ctrl.search = search;
  ctrl.addSelectedToPinned = addSelectedToPinned;
  ctrl.remove = remove;
  ctrl.update = update;

  init();

  function init() {
    loadEntries();
  }

  function loadEntries() {
    ctrl.loading = true;

    return PinnedHelpEntries
      .get()
      .then(entries => {
        // Make sure to store a copy as we may be mutating this!
        angular.copy(entries, ctrl.entries);
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function search(query) {
    return hubApiService.helpSearch({q: query, ignore_for_stats: true});
  }

  function addSelectedToPinned() {
    if (ctrl.searchSelectedEntry) {
      const item = ctrl.searchSelectedEntry.item;
      addToEntries(item);
      ctrl.searchText = '';
      ctrl.searchSelectedEntry = null;
    }
  }

  function remove(ix) {
    ctrl.entries.splice(ix, 1);
  }

  function update() {
    ctrl.saving = true;

    return PinnedHelpEntries
      .update(ctrl.entries)
      .then(() => {
        logger.success('Updated the list of pinned help entries');
        return loadEntries();
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function addToEntries(item) {
    const id = item.id;

    const exists = _.some(ctrl.entries, e => e.id === id);

    if (!exists) {
      ctrl.entries.push(item);
    }
  }
}
