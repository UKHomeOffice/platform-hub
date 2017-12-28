export const KubeConfigHelperPopupController = function ($mdDialog, icons, kubeId, token) {
  'ngInject';

  const ctrl = this;

  ctrl.copyIcon = icons.copy;

  ctrl.clusterName = token.cluster.name;

  const contextName = `${token.cluster.name}_${token.project.shortname}`;
  const userName = `${kubeId}_${contextName}`;

  ctrl.clusterCommands = `kubectl config set-cluster ${token.cluster.name} --server=${token.cluster.api_url} && kubectl config set clusters.${token.cluster.name}.certificate-authority-data ${token.cluster.ca_cert_encoded}`;

  ctrl.credentialsCommands = `kubectl config set-credentials ${userName} --token=${token.token}`;

  ctrl.contextCommands = `kubectl config set-context ${contextName} --cluster=${token.cluster.name} --user=${userName}`;

  ctrl.exampleKubectlCommand = `kubectl --context=${contextName} --namespace=<namespace> get pods`;

  ctrl.close = $mdDialog.hide;
};
