export const onboardingTrigger = function ($state, Me, logger) {
  'ngInject';

  return function () {
    return Me
      .refresh()
      .then(me => {
        if (!me.flags.agreed_to_terms_of_service) {
          logger.warning('You need to agree to the platform Terms of Service');
          $state.go('terms-of-service');
        }
      });
  };
};
