export const SearchComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./search.html'),
  controller: SearchController
};

function SearchController($state, $sce, hubApiService, PinnedHelpEntries, icons, _) {
  'ngInject';

  const ctrl = this;

  ctrl.query = ctrl.transition && ctrl.transition.params().q;

  ctrl.supportRequestsIcon = icons.supportRequests;
  ctrl.docsIcon = icons.docs;

  ctrl.loading = false;
  ctrl.initialState = true;
  ctrl.searchText = ctrl.query;
  ctrl.results = [];

  ctrl.search = search;
  ctrl.clear = clear;

  init();

  function init() {
    if (ctrl.query) {
      fetchResults();
    } else {
      fetchPinnedItems();
    }
  }

  function search() {
    $state.go($state.current, {q: ctrl.searchText}, {reload: true});
  }

  function clear() {
    $state.go($state.current, {q: undefined}, {reload: true});
  }

  function fetchResults() {
    ctrl.loading = true;
    ctrl.results = [];

    const params = {
      q: ctrl.searchText
    };

    return hubApiService
      .helpSearch(params)
      .then(results => {
        ctrl.results = processResults(results);
        ctrl.initialState = false;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function fetchPinnedItems() {
    ctrl.loading = true;

    PinnedHelpEntries
      .get()
      .then(items => {
        angular.copy(items, ctrl.results);
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function processResults(results) {
    return results.map(r => {
      const item = _.clone(r.item);

      if (r.highlights.title && r.highlights.title.length > 0) {
        item.title = $sce.trustAsHtml(r.highlights.title[0]);
      }

      if (r.highlights.content && r.highlights.content.length > 0) {
        item.content = $sce.trustAsHtml(r.highlights.content.join('...'));
      }

      return item;
    });
  }
}
