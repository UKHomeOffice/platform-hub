export const onboardingTrigger = function ($state, Me) {
  'ngInject';

  return function () {
    return Me
      .refresh()
      .then(me => {
        if (!me.flags.completed_hub_onboarding) {
          $state.go('onboarding.hub-setup');
        }
      });
  };
};
