export const hubApiService = function ($rootScope, $http, $q, logger, events, apiEndpoint, _) {
  'ngInject';

  let meDataPromise = null;

  const service = {};

  service.getMe = getMe;
  service.deleteMeIdentity = deleteMeIdentity;
  service.getUsers = buildCollectionFetcher('users');
  service.searchUsers = searchUsers;
  service.makeAdmin = makeAdmin;
  service.revokeAdmin = revokeAdmin;
  service.getProjects = buildCollectionFetcher('projects');
  service.getProject = buildResourceFetcher('projects');
  service.createProject = createProject;
  service.updateProject = updateProject;
  service.deleteProject = deleteProject;
  service.getProjectMemberships = getProjectMemberships;
  service.addProjectMembership = addProjectMembership;
  service.removeProjectMembership = removeProjectMembership;

  return service;

  function getMe() {
    if (_.isEmpty(meDataPromise)) {
      meDataPromise = $http
        .get(`${apiEndpoint}/me`)
        .then(response => {
          const me = response.data;

          $rootScope.$broadcast(events.api.me.updated, me);
          logger.debug(me);

          return me;
        })
        .catch(response => {
          logger.error('Failed to fetch profile data – the API might be down. Try again later.');
          return $q.reject(response);
        })
        .finally(() => {
          meDataPromise = null;
        });
    }
    return meDataPromise;
  }

  function deleteMeIdentity(provider) {
    return $http
      .delete(`${apiEndpoint}/me/identities/${provider}`)
      .catch(response => {
        logger.error(`Failed to delete the identity for '${provider}' – the API might be down. Try again later.`);
        return $q.reject(response);
      });
  }

  function searchUsers(query) {
    return $http
      .get(`${apiEndpoint}/users/search/${query}`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error('Failed to search for users – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function makeAdmin(userId) {
    return $http
      .post(`${apiEndpoint}/users/${userId}/make_admin`)
      .catch(response => {
        logger.error('Failed to make the user an admin – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function revokeAdmin(userId) {
    return $http
      .post(`${apiEndpoint}/users/${userId}/revoke_admin`)
      .catch(response => {
        logger.error('Failed to revoke admin status for the – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function createProject(fields) {
    return $http
      .post(`${apiEndpoint}/projects`, fields)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error('Failed to create a new project. The shortname provided may be taken, or the API might be down.');
        return $q.reject(response);
      });
  }

  function updateProject(id, fields) {
    return $http
      .put(`${apiEndpoint}/projects/${id}`, fields)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error('Failed to update the project. The shortname provided may be taken, or the API might be down.');
        return $q.reject(response);
      });
  }

  function deleteProject(projectId) {
    return $http
      .delete(`${apiEndpoint}/projects/${projectId}`)
      .catch(response => {
        logger.error('Failed to delete project – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function getProjectMemberships(projectId) {
    return $http
      .get(`${apiEndpoint}/projects/${projectId}/memberships`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error('Failed to fetch memberships for project – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function addProjectMembership(projectId, userId) {
    return $http
      .put(`${apiEndpoint}/projects/${projectId}/memberships/${userId}`)
      .catch(response => {
        logger.error('Failed to add team member to project – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function removeProjectMembership(projectId, userId) {
    return $http
      .delete(`${apiEndpoint}/projects/${projectId}/memberships/${userId}`)
      .catch(response => {
        logger.error('Failed to remove team member from project – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function buildCollectionFetcher(name) {
    return function () {
      return $http
        .get(`${apiEndpoint}/${name}`)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(`Failed to fetch ${name} – the API might be down. Try again later.`);
          return $q.reject(response);
        });
    };
  }

  function buildResourceFetcher(name) {
    return function (id) {
      return $http
        .get(`${apiEndpoint}/${name}/${id}`)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error('Failed to fetch item – the API might be down. Try again later.');
          return $q.reject(response);
        });
    };
  }
};
