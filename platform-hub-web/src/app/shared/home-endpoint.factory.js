export const homeEndpoint = function ($state) {
  return $state.href('home', {}, {absolute: true});
};
