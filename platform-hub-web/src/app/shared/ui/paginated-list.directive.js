export const PaginatedListDirective = function () {
  return {
    restrict: 'AE',
    transclude: true,
    scope: {
      items: '=pageItems',
      fetch: '&pageFetch'
    },
    template: require('./paginated-list.html'),
    controller: PaginatedListController,
    bindToController: true,
    controllerAs: '$ctrl'
  };
};

function PaginatedListController() {
  'ngInject';

  const ctrl = this;

  ctrl.currentPage = 1;

  ctrl.onPageChange = onPageChange;

  function onPageChange(page) {
    return ctrl
      .fetch({page})
      .then(() => {
        ctrl.currentPage = page;
      });
  }
}
