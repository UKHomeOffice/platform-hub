export const KubernetesTokenEscalatePrivilegePopupController = function ($scope, $mdDialog, token, Projects, KubernetesGroups, KubernetesTokens, logger, _) {
  'ngInject';

  $scope._ = _;

  const ctrl = this;

  ctrl.expiryOptions = [
    {label: '10 mins', value: 10 * 60},
    {label: '30 mins', value: 30 * 60},
    {label: '1 hour', value: 1 * 60 * 60},
    {label: '2 hours', value: 2 * 60 * 60},
    {label: '4 hours', value: 4 * 60 * 60},
    {label: '8 hours', value: 8 * 60 * 60}
  ];

  ctrl.loading = true;
  ctrl.processing = false;
  ctrl.groups = {};
  ctrl.token = token;
  ctrl.data = {};

  ctrl.cancel = $mdDialog.cancel;
  ctrl.escalate = escalate;

  init();

  function init() {
    loadGroups();
  }

  function loadGroups() {
    ctrl.loading = true;

    return Projects
      .getAllKubernetesGroupsGrouped(ctrl.token.project.id, 'user')
      .then(grouped => {
        const seen = {};
        ctrl.groups = Object.keys(grouped).reduce((acc, key) => {
          const forCluster = KubernetesGroups
            .filterGroupsForCluster(grouped[key], ctrl.token.cluster.name)
            .filter(g => g.is_privileged);

          // Need to consider dup groups between services etc.
          const dedupped = forCluster.filter(g => {
            const allowed = !seen[g.name];
            seen[g.name] = 1;
            return allowed;
          });

          if (!_.isEmpty(dedupped)) {
            acc[key] = dedupped;
          }

          return acc;
        }, {});
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function escalate() {
    ctrl.processing = true;

    KubernetesTokens
      .escalatePrivilege(
        ctrl.token.id,
        ctrl.data.group,
        ctrl.data.expiresInSecs
      )
      .then(() => {
        logger.success('Successfully granted a short lived escalation of privilege for the token');
        $mdDialog.hide();
      })
      .catch($mdDialog.cancel);
  }
};
