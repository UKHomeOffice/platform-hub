export const SupportRequestsFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./support-requests-form.html'),
  controller: SupportRequestsFormController
};

function SupportRequestsFormController(hubApiService) {
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
      })
      .finally(() => {
        ctrl.sending = false;
      });
  }
}
