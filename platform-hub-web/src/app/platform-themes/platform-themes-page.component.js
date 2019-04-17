/* eslint camelcase: 0 */

export const PlatformThemesPageComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./platform-themes-page.html'),
  controller: PlatformThemesPageController
};

function PlatformThemesPageController(hubApiService, icons, FeatureFlags, featureFlagKeys, UserScopes, _) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition.params().id;

  ctrl.FeatureFlags = FeatureFlags;
  ctrl.featureFlagKeys = featureFlagKeys;

  ctrl.icons = {
    internal_route: icons.internalLink,
    external_link: icons.externalLink,
    support_request: icons.supportRequests,
    plain_text: icons.text
  };

  ctrl.loading = true;
  ctrl.theme = null;

  ctrl.resourceIsVisible = resourceIsVisible;

  init();

  function init() {
    loadTheme();
  }

  function loadTheme() {
    if (_.isNull(id) || _.isEmpty(id)) {
      ctrl.loading = false;
      return;
    }

    ctrl.loading = true;
    ctrl.theme = null;

    hubApiService
      .getPlatformTheme(id)
      .then(theme => {
        ctrl.theme = theme;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function resourceIsVisible(resource) {
    const enabled = resource.kind !== 'support_request' || ctrl.FeatureFlags.isEnabled(ctrl.featureFlagKeys.supportRequests);
    return enabled && resource.visible && UserScopes.isVisibleToCurrentUser(resource.user_scope);
  }
}
