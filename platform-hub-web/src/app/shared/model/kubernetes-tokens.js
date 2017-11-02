export const KubernetesTokens = function (hubApiService) {
  'ngInject';

  const model = {};

  model.getToken = hubApiService.getKubernetesToken;
  model.deleteToken = hubApiService.deleteKubernetesToken;

  model.getUserTokens = hubApiService.getKubernetesUserTokens;
  model.createUserToken = hubApiService.createKubernetesUserToken;
  model.updateUserToken = hubApiService.updateKubernetesUserToken;

  model.getRobotTokens = hubApiService.getKubernetesRobotTokens;
  model.createRobotToken = hubApiService.createKubernetesRobotToken;
  model.updateRobotToken = hubApiService.updateKubernetesRobotToken;

  model.revokeToken = revokeToken;

  return model;

  function revokeToken(tokenValue) {
    return hubApiService.revokeKubernetesToken({token: tokenValue});
  }
};
