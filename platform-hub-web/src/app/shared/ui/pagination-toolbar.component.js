export const PaginationToolbarComponent = {
  bindings: {
    currentPage: '=',
    perPage: '<',
    total: '<',
    onPageChange: '&'
  },
  template: require('./pagination-toolbar.html'),
  controller: PaginationToolbarController
};

function PaginationToolbarController($scope, _) {
  'ngInject';

  const ctrl = this;

  $scope._ = _;

  ctrl.totalPages = 0;

  const maybeRecomputePages = (newVal, oldVal) => {
    if (newVal !== oldVal) {
      computePages();
    }
  };

  $scope.$watch(() => ctrl.perPage, maybeRecomputePages);
  $scope.$watch(() => ctrl.total, maybeRecomputePages);

  computePages();

  function computePages() {
    ctrl.totalPages = Math.ceil(ctrl.total / ctrl.perPage);
  }
}
