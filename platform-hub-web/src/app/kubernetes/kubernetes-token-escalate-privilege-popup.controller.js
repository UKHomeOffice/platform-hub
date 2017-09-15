export const KubernetesTokenEscalatePrivilegePopupController = function ($mdDialog, user, cluster, hubApiService, logger, _) {
  'ngInject';

  const ctrl = this;

  ctrl.expiryOptions = [
    {label: '10 mins', value: 10 * 60},
    {label: '30 mins', value: 30 * 60},
    {label: '1 hour', value: 1 * 60 * 60},
    {label: '2 hours', value: 2 * 60 * 60}
  ];

  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.groups = [];
  ctrl.user = user;
  ctrl.cluster = cluster;
  ctrl.data = {};

  ctrl.cancel = $mdDialog.cancel;
  ctrl.escalate = escalate;

  init();

  function init() {
    loadGroups();
  }

  function loadGroups() {
    ctrl.loading = true;

    hubApiService
      .getPrivilegedGroupsForKubernetesTokens()
      .then(groups => {
        ctrl.groups = groups;
        ctrl.data.group = _.get(groups[0], 'id');
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function escalate() {
    ctrl.processing = true;

    hubApiService
      .escalatePrivilegeForKubernetesTokens(
        ctrl.user.id,
        ctrl.cluster,
        ctrl.data.group,
        ctrl.data.expiresInSecs
      )
      .then(() => {
        logger.success('Successfully granted a short lived escalation of privilege');
        $mdDialog.hide();
      });
  }
};
