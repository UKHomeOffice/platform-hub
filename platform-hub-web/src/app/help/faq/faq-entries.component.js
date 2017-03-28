export const FaqEntriesComponent = {
  template: require('./faq-entries.html'),
  controller: FaqEntriesController
};

function FaqEntriesController(AppSettings) {
  'ngInject';

  const ctrl = this;

  ctrl.AppSettings = AppSettings;
}
