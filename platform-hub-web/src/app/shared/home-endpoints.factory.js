export const homeEndpoints = function ($state) {
  'ngInject';

  return {
    home: $state.href('home', {}, {absolute: true}),
    homePreload: $state.href('home.preload', {}, {absolute: true})
  };
};
