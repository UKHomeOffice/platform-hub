export const HomePreloadComponent = {
  template: require('./home-preload.html'),
  controller: HomePreloadController
};

function HomePreloadController($state, Me) {
  'ngInject';

  init();

  function init() {
    Me
      .refresh()
      .then(() => {
        $state.go('home');
      });
  }
}
