export const TermsOfServiceComponent = {
  template: require('./terms-of-service.html'),
  controller: TermsOfServiceController
};

function TermsOfServiceController($state, $sce, AppSettings, Me, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.AppSettings = AppSettings;
  ctrl.Me = Me;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.text = '';

  ctrl.agree = agree;

  init();

  function init() {
    ctrl.loading = true;

    Me
      .refresh()
      .then(() => {
        return AppSettings
          .refresh()
          .then(() => {
            ctrl.text = $sce.trustAsHtml(AppSettings.getTermsOfServiceText());
          });
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function agree() {
    ctrl.saving = true;

    Me
      .agreeTermsOfService()
      .then(meData => {
        logger.success('Thank you for agreeing to the platform Terms of Service');

        if (!meData.flags.completed_hub_onboarding) {
          $state.go('onboarding.hub-setup');
        }
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
