import angular from 'angular';

export const Projects = function ($window, $q, apiBackoffTimeMs, hubApiService, _) {
  'ngInject';

  const model = {};

  let fetcherPromise = null;

  model.all = [];

  model.refresh = refresh;
  model.get = hubApiService.getProject;
  model.create = hubApiService.createProject;
  model.update = hubApiService.updateProject;
  model.delete = hubApiService.deleteProject;

  model.getMemberships = hubApiService.getProjectMemberships;
  model.addMembership = hubApiService.addProjectMembership;
  model.removeMembership = hubApiService.removeProjectMembership;
  model.membershipRoleCheck = hubApiService.projectMembershipRoleCheck;
  model.setMembershipRole = hubApiService.projectSetMembershipRole;
  model.unsetMembershipRole = hubApiService.projectUnsetMembershipRole;

  model.getKubernetesClusters = hubApiService.getProjectKubernetesClusters;
  model.getKubernetesGroups = hubApiService.getProjectKubernetesGroups;
  model.getKubernetesUserTokens = hubApiService.getProjectKubernetesUserTokens;
  model.getKubernetesUserToken = hubApiService.getProjectKubernetesUserToken;
  model.createKubernetesUserToken = hubApiService.createProjectKubernetesUserToken;
  model.updateKubernetesUserToken = hubApiService.updateProjectKubernetesUserToken;
  model.deleteKubernetesUserToken = hubApiService.deleteProjectKubernetesUserToken;

  model.getServices = hubApiService.getProjectServices;
  model.getService = hubApiService.getProjectService;
  model.createService = hubApiService.createProjectService;
  model.updateService = hubApiService.updateProjectService;
  model.deleteService = hubApiService.deleteProjectService;
  model.getServiceKubernetesGroups = hubApiService.getProjectServiceKubernetesGroups;
  model.getServiceKubernetesRobotTokens = hubApiService.getProjectServiceKubernetesRobotTokens;
  model.getServiceKubernetesRobotToken = hubApiService.getProjectServiceKubernetesRobotToken;
  model.createServiceKubernetesRobotToken = hubApiService.createProjectServiceKubernetesRobotToken;
  model.updateServiceKubernetesRobotToken = hubApiService.updateProjectServiceKubernetesRobotToken;
  model.deleteServiceKubernetesRobotToken = hubApiService.deleteProjectServiceKubernetesRobotToken;

  model.getAllKubernetesGroupsGrouped = getAllKubernetesGroupsGrouped;

  model.getBills = hubApiService.getProjectBills;

  model.getDockerRepos = hubApiService.getProjectDockerRepos;
  model.createDockerRepo = hubApiService.createProjectDockerRepo;
  model.deleteDockerRepo = hubApiService.deleteProjectDockerRepo;

  return model;

  function refresh(force) {
    if (force || _.isNull(fetcherPromise)) {
      fetcherPromise = hubApiService
        .getProjects()
        .then(projects => {
          angular.copy(projects, model.all);
          return model.all;
        })
        .finally(() => {
          // Reuse the same promise for some time, to prevent smashing the API
          $window.setTimeout(() => {
            fetcherPromise = null;
          }, apiBackoffTimeMs);
        });
    }
    return fetcherPromise;
  }

  function getAllKubernetesGroupsGrouped(projectId, target) {
    return model.getServices(projectId)
      .then(services => {
        const projectGroupsFetch = model.getKubernetesGroups(projectId, target);

        const serviceGroupsFetches = services.map(s => model.getServiceKubernetesGroups(projectId, s.id, target));

        const allFetches = [projectGroupsFetch].concat(serviceGroupsFetches);

        return $q
          .all(allFetches)
          .then(data => {
            return data.reduce((acc, groups, ix) => {
              // The first one is for project level groups
              if (ix === 0) {
                acc['Project level groups'] = groups;
              } else {
                const service = services[ix - 1];
                acc[`Service: ${service.name}`] = groups;
              }
              return acc;
            }, {});
          });
      });
  }
};
