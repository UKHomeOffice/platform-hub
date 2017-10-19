export const KubernetesTokens = function (hubApiService) {
  'ngInject';

  const model = {};

  model.getRobotToken = hubApiService.getKubernetesRobotToken;
  model.createRobotToken = hubApiService.createKubernetesRobotToken;
  model.updateRobotToken = hubApiService.updateKubernetesRobotToken;

  return model;
};
