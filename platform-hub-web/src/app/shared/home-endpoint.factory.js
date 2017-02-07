export const homeEndpoint = function ($state) {
  'ngInject';

  return $state.href('home', {}, {absolute: true});
};
