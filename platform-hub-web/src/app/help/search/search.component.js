export const SearchComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./search.html'),
  controller: SearchController
};

function SearchController($state, $sce, hubApiService, icons, _) {
  'ngInject';

  const ctrl = this;

  const query = ctrl.transition && ctrl.transition.params().q;

  ctrl.supportRequestsIcon = icons.supportRequests;
  ctrl.docsIcon = icons.docs;

  ctrl.loading = false;
  ctrl.initialState = true;
  ctrl.searchText = query;
  ctrl.results = [];

  ctrl.search = search;
  ctrl.clear = clear;

  init();

  function init() {
    if (query) {
      fetchResults();
    }
  }

  function search() {
    $state.go($state.current, {q: ctrl.searchText}, {reload: true});
  }

  function clear() {
    $state.go($state.current, {q: undefined}, {reload: true});
  }

  function fetchResults() {
    ctrl.initialState = false;
    ctrl.loading = true;
    ctrl.results = [];

    const params = {
      q: ctrl.searchText
    };

    return hubApiService
      .helpSearch(params)
      .then(results => {
        ctrl.results = processResults(results);
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
