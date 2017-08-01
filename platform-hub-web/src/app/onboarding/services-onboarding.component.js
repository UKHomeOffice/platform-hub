export const ServicesOnboardingComponent = {
  template: require('./services-onboarding.html'),
  controller: ServicesOnboardingController
};

function ServicesOnboardingController($state, $mdDialog, Me, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.busy = true;
  ctrl.processing = false;

  ctrl.finish = finish;

  function finish(targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Please accept and confirm the following details before continuing')
      .textContent('By continuing, you accept and confirm that your GitHub account has a) 2-Factor Auth (2FA) set up and switched on, and b) a full name has been set on your GitHub profile. Please don\'t continue until this is the case.')
      .ariaLabel('Accept and confirm details before continuing with services onboarding')
      .targetEvent(targetEvent)
      .ok('Continue')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.processing = true;

        Me
          .completeServicesOnboarding()
          .then(() => {
            logger.success('You have successfully onboarded to services');
            $state.go('home');
          })
          .finally(() => {
            ctrl.processing = false;
          });
      });
  }
}
