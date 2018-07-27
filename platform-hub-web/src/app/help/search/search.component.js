export const SearchComponent = {
  template: require('./search.html'),
  controller: SearchController
};

function SearchController($sce, hubApiService, icons, _) {
  'ngInject';

  const ctrl = this;

  ctrl.supportRequestsIcon = icons.supportRequests;

  ctrl.loading = false;
  ctrl.initialState = true;
  ctrl.searchText = '';
  ctrl.results = [];

  ctrl.fetchResults = fetchResults;

  function fetchResults() {
    if (_.isNull(ctrl.searchText) || _.isEmpty(ctrl.searchText)) {
      return;
    }

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
