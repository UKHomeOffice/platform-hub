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

  model.getServices = hubApiService.getProjectServices;
  model.getService = hubApiService.getProjectService;
  model.createService = hubApiService.createProjectService;
  model.updateService = hubApiService.updateProjectService;
  model.deleteService = hubApiService.deleteProjectService;

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
};
