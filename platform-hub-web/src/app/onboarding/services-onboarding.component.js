export const ServicesOnboardingComponent = {
  template: require('./services-onboarding.html'),
  controller: ServicesOnboardingController
};

function ServicesOnboardingController($state, Me, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.busy = true;
  ctrl.processing = false;

  ctrl.finish = finish;

  function finish() {
    ctrl.processing = true;

    Me
      .completeServicesOnboarding()
      .then(() => {
        logger.success('You have successfully been onboarded to services');
        $state.go('home');
      })
      .finally(() => {
        ctrl.processing = false;
      });
  }
}
