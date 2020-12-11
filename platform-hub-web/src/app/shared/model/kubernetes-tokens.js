export const KubernetesTokens = function (hubApiService) {
  'ngInject';

  const model = {};

  model.getToken = hubApiService.getKubernetesToken;
  model.deleteToken = hubApiService.deleteKubernetesToken;

  model.getUserTokens = hubApiService.getKubernetesUserTokens;
  model.createUserToken = hubApiService.createKubernetesUserToken;
  model.updateUserToken = hubApiService.updateKubernetesUserToken;
  model.regenerateUserToken = hubApiService.regenerateKubernetesUserToken;

  model.getRobotTokens = hubApiService.getKubernetesRobotTokens;
  model.createRobotToken = hubApiService.createKubernetesRobotToken;
  model.updateRobotToken = hubApiService.updateKubernetesRobotToken;
  model.regenerateRobotToken = hubApiService.regenerateKubernetesRobotToken;

  model.revokeToken = revokeToken;
  model.escalatePrivilege = hubApiService.escalatePrivilegeForKubernetesTokens;

  return model;

  function revokeToken(tokenValue) {
    return hubApiService.revokeKubernetesToken({token: tokenValue});
  }
};
