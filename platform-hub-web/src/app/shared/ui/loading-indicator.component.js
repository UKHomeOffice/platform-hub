export const LoadingIndicatorComponent = {
  bindings: {
    loading: '<'
  },
  template: '<md-progress-linear md-mode="indeterminate" ng-if="$ctrl.loading"></md-progress-linear>'
};
