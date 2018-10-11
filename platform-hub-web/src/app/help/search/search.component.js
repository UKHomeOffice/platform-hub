export const SearchComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./search.html'),
  controller: SearchController
};

function SearchController($q, $state, $sce, hubApiService, PinnedHelpEntries, roleCheckerService, icons, _) {
  'ngInject';

  const ctrl = this;

  ctrl.query = ctrl.transition && ctrl.transition.params().q;

  ctrl.supportRequestsIcon = icons.supportRequests;
  ctrl.qaEntriesIcon = icons.qaEntries;
  ctrl.docsIcon = icons.docs;

  ctrl.isAdmin = false;
  ctrl.loading = false;
  ctrl.initialState = true;
  ctrl.searchText = ctrl.query;
  ctrl.results = [];
  ctrl.stats = [];

  ctrl.search = search;
  ctrl.clear = clear;
  ctrl.hideSearchQueryStat = hideSearchQueryStat;

  init();

  function init() {
    loadAdminStatus();

    if (ctrl.query) {
      fetchResults();
    } else {
      ctrl.loading = true;

      $q.all([
        fetchPinnedItems(),
        fetchStats()
      ]).finally(() => {
        ctrl.loading = false;
      });
    }
  }

  function loadAdminStatus() {
    return roleCheckerService
      .hasHubRole('admin')
      .then(hasRole => {
        ctrl.isAdmin = hasRole;
      });
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
    return PinnedHelpEntries
      .get()
      .then(items => {
        angular.copy(items, ctrl.results);
      });
  }

  function fetchStats() {
    return hubApiService
      .helpSearchQueryStats()
      .then(stats => {
        ctrl.stats = stats;
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

  function hideSearchQueryStat(query) {
    return hubApiService
      .hideHelpSearchQueryStat({q: query})
      .then(fetchStats);
  }
}
