export const FaqEntriesComponent = {
  template: require('./faq-entries.html'),
  controller: FaqEntriesController
};

function FaqEntriesController(AppSettings, FeatureFlags, featureFlagKeys, icons) {
  'ngInject';

  const ctrl = this;

  ctrl.AppSettings = AppSettings;
  ctrl.FeatureFlags = FeatureFlags;
  ctrl.featureFlagKeys = featureFlagKeys;
  ctrl.linkIcon = icons.link;
}
