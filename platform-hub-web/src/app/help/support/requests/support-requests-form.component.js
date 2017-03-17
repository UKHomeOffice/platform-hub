export const SupportRequestsFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./support-requests-form.html'),
  controller: SupportRequestsFormController
};

function SupportRequestsFormController($mdDialog, hubApiService) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.sending = false;
  ctrl.template = null;
  ctrl.data = {};
  ctrl.issueUrl = null;

  ctrl.sendRequest = sendRequest;

  init();

  function init() {
    loadTemplate();
  }

  function loadTemplate() {
    ctrl.loading = true;
    ctrl.template = null;

    hubApiService
      .getSupportRequestTemplate(id)
      .then(template => {
        ctrl.template = template;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function sendRequest() {
    ctrl.sending = true;

    hubApiService
      .createSupportRequest(ctrl.template.id, ctrl.data)
      .then(result => {
        ctrl.issueUrl = result.url;

        showIssueUrlDialog();
      })
      .finally(() => {
        ctrl.sending = false;
      });
  }

  function showIssueUrlDialog() {
    $mdDialog.show(
      $mdDialog.alert()
        .clickOutsideToClose(true)
        .title('Your support request has been submitted')
        .htmlContent(`<p class="md-body-1">See the following GitHub issue for details and updates:</p><p class="md-body-1"><strong><a href="${ctrl.issueUrl}" target="_blank">${ctrl.issueUrl}</a></strong></p>`)
        .ariaLabel('Support request GitHub issue URL')
        .ok('Got it')
    );
  }
}
