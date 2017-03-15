/* eslint camelcase: 0, object-shorthand: 0 */

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
  service.createProject = buildResourceCreator('projects');
  service.updateProject = buildResourceUpdater('projects');
  service.deleteProject = buildResourceDeletor('projects');
  service.getProjectMemberships = getProjectMemberships;
  service.addProjectMembership = addProjectMembership;
  service.removeProjectMembership = removeProjectMembership;
  service.projectSetRole = projectSetRole;
  service.projectUnsetRole = projectUnsetRole;
  service.userOnboardGitHub = userOnboardGitHub;
  service.userOffboardGitHub = userOffboardGitHub;
  service.getSupportRequestTemplates = buildCollectionFetcher('support_request_templates');
  service.getSupportRequestTemplate = buildResourceFetcher('support_request_templates');
  service.createSupportRequestTemplate = buildResourceCreator('support_request_templates');
  service.updateSupportRequestTemplate = buildResourceUpdater('support_request_templates');
  service.deleteSupportRequestTemplate = buildResourceDeletor('support_request_templates');
  service.getSupportRequestTemplateFormFieldTypes = getSupportRequestTemplateFormFieldTypes;
  service.createSupportRequest = createSupportRequest;

  return service;

  function getMe() {
    if (_.isNull(meDataPromise)) {
      meDataPromise = $http
        .get(`${apiEndpoint}/me`)
        .then(response => {
          const me = response.data;

          $rootScope.$broadcast(events.api.me.updated, me);

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
        logger.error(buildErrorMessageFromResponse(`Failed to delete the identity for '${provider}'`, response));
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
        logger.error(buildErrorMessageFromResponse('Failed to search for users', response));
        return $q.reject(response);
      });
  }

  function makeAdmin(userId) {
    return $http
      .post(`${apiEndpoint}/users/${userId}/make_admin`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to make the user an admin', response));
        return $q.reject(response);
      });
  }

  function revokeAdmin(userId) {
    return $http
      .post(`${apiEndpoint}/users/${userId}/revoke_admin`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to revoke admin status', response));
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
        logger.error(buildErrorMessageFromResponse('Failed to fetch memberships for project', response));
        return $q.reject(response);
      });
  }

  function addProjectMembership(projectId, userId) {
    return $http
      .put(`${apiEndpoint}/projects/${projectId}/memberships/${userId}`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to add team member to project', response));
        return $q.reject(response);
      });
  }

  function removeProjectMembership(projectId, userId) {
    return $http
      .delete(`${apiEndpoint}/projects/${projectId}/memberships/${userId}`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to remove team member from project', response));
        return $q.reject(response);
      });
  }

  function projectSetRole(projectId, userId, role) {
    return $http
      .put(`${apiEndpoint}/projects/${projectId}/memberships/${userId}/role/${role}`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to set project team role', response));
        return $q.reject(response);
      });
  }

  function projectUnsetRole(projectId, userId, role) {
    return $http
      .delete(`${apiEndpoint}/projects/${projectId}/memberships/${userId}/role/${role}`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to unset project team role', response));
        return $q.reject(response);
      });
  }

  function userOnboardGitHub(userId) {
    return $http
      .post(`${apiEndpoint}/users/${userId}/onboard_github`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to onboard user to GitHub ', response));
        return $q.reject(response);
      });
  }

  function userOffboardGitHub(userId) {
    return $http
      .post(`${apiEndpoint}/users/${userId}/offboard_github`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to offboard user from GitHub', response));
        return $q.reject(response);
      });
  }

  function getSupportRequestTemplateFormFieldTypes() {
    return $http
      .get(`${apiEndpoint}/support_request_templates/form_field_types`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to fetch field types', response));
        return $q.reject(response);
      });
  }

  function createSupportRequest(templateId, data) {
    return $http
      .post(`${apiEndpoint}/support_requests`, {
        template_id: templateId,
        data: data
      })
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to create support request', response));
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
          logger.error(buildErrorMessageFromResponse('Failed to fetch items', response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceFetcher(resource) {
    return function (id) {
      return $http
        .get(`${apiEndpoint}/${resource}/${id}`)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to fetch item', response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceCreator(resource) {
    return function (data) {
      return $http
        .post(`${apiEndpoint}/${resource}`, data)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to create item', response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceUpdater(resource) {
    return function (id, data) {
      return $http
        .put(`${apiEndpoint}/${resource}/${id}`, data)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse('Failed to update item', response));
          return $q.reject(response);
        });
    };
  }

  function buildResourceDeletor(resource) {
    return function (id) {
      return $http
      .delete(`${apiEndpoint}/${resource}/${id}`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to delete item', response));
        return $q.reject(response);
      });
    };
  }

  function buildErrorMessageFromResponse(prefix, response) {
    const errorDetails = _.get(response.data, 'error.message');
    let msg = prefix;
    if (errorDetails) {
      msg += `: ${errorDetails}`;
    }
    return msg;
  }
};
