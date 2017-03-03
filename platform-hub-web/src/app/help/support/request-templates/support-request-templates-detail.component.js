export const SupportRequestTemplatesDetailComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./support-request-templates-detail.html'),
  controller: SupportRequestTemplatesDetailController
};

function SupportRequestTemplatesDetailController($mdDialog, $state, hubApiService, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.template = null;

  ctrl.deleteTemplate = deleteTemplate;

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

  function deleteTemplate(targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the support request template permanently from the hub.')
      .ariaLabel('Confirm deletion of support request template')
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.loading = true;

        hubApiService
          .deleteSupportRequestTemplate(ctrl.template.id)
          .then(() => {
            logger.success('Support request template deleted');
            $state.go('help.support.request-templates.list');
          })
          .finally(() => {
            ctrl.loading = false;
          });
      });
  }
}
