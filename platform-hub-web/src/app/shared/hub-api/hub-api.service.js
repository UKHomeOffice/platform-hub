/* eslint camelcase: 0, object-shorthand: 0 */

export const hubApiService = function ($rootScope, $http, $q, logger, events, apiEndpoint, _) {
  'ngInject';

  const service = {};

  service.getMe = getMe;
  service.getIdentityFlowStartEndpoint = getIdentityFlowStartEndpoint;
  service.deleteMeIdentity = deleteMeIdentity;
  service.completeHubOnboarding = completeHubOnboarding;
  service.completeServicesOnboarding = completeServicesOnboarding;
  service.agreeTermsOfService = agreeTermsOfService;
  service.globalAnnouncementsMarkAllRead = globalAnnouncementsMarkAllRead;

  service.getUsers = buildCollectionFetcher('users');
  service.getUser = buildResourceFetcher('users');
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
  service.getSupportRequestTemplateFormFieldTypes = buildSimpleFetcher('support_request_templates/form_field_types', 'field types');
  service.getSupportRequestTemplateGitHubRepos = buildSimpleFetcher('support_request_templates/git_hub_repos', 'GitHub repos for support requests');

  service.createSupportRequest = createSupportRequest;

  service.getPlatformThemes = buildCollectionFetcher('platform_themes');
  service.getPlatformTheme = buildResourceFetcher('platform_themes');
  service.createPlatformTheme = buildResourceCreator('platform_themes');
  service.updatePlatformTheme = buildResourceUpdater('platform_themes');
  service.deletePlatformTheme = buildResourceDeletor('platform_themes');

  service.getAppSettings = buildSimpleFetcher('app_settings', 'app settings');
  service.updateAppSettings = buildSimpleUpdater('app_settings', 'app settings');

  service.getContactLists = buildCollectionFetcher('contact_lists');
  service.getContactList = buildResourceFetcher('contact_lists');
  service.updateContactList = buildResourceUpdater('contact_lists');
  service.deleteContactList = buildResourceDeletor('contact_lists');

  service.getGlobalAnnouncements = buildSimpleFetcher('announcements/global', 'global announcements');
  service.getAllAnnouncements = buildCollectionFetcher('announcements');
  service.getAnnouncement = buildResourceFetcher('announcements');
  service.createAnnouncement = buildResourceCreator('announcements');
  service.updateAnnouncement = buildResourceUpdater('announcements');
  service.deleteAnnouncement = buildResourceDeletor('announcements');
  service.announcementMarkSticky = announcementMarkSticky;
  service.announcementUnmarkSticky = announcementUnmarkSticky;

  service.getKubernetesClusters = buildSimpleFetcher('kubernetes/clusters', 'kubernetes clusters');
  service.getKubernetesTokens = getKubernetesTokens;
  service.deleteKubernetesToken = deleteKubernetesToken;
  service.createOrUpdateKubernetesToken = createOrUpdateKubernetesToken;
  service.getKubernetesTokensChangeset = getKubernetesTokensChangeset;
  service.syncKubernetesTokens = syncKubernetesTokens;
  service.claimKubernetesToken = claimKubernetesToken;

  return service;

  function getMe() {
    return $http
      .get(`${apiEndpoint}/me`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error('Failed to fetch profile data – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function getIdentityFlowStartEndpoint(provider) {
    return `${apiEndpoint}/identity_flows/start/${provider}`;
  }

  function deleteMeIdentity(provider) {
    if (_.isNull(provider) || _.isEmpty(provider)) {
      throw new Error('"provider" argument not specified or empty');
    }

    return $http
      .delete(`${apiEndpoint}/me/identities/${provider}`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to delete the identity for '${provider}'`, response));
        return $q.reject(response);
      });
  }

  function completeHubOnboarding(data) {
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/me/complete_hub_onboarding`, data)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to complete hub onboarding', response));
        return $q.reject(response);
      });
  }

  function completeServicesOnboarding() {
    return $http
      .post(`${apiEndpoint}/me/complete_services_onboarding`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to complete services onboarding', response));
        return $q.reject(response);
      });
  }

  function agreeTermsOfService() {
    return $http
      .post(`${apiEndpoint}/me/agree_terms_of_service`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Error occurred whilst agreeing to terms of service', response));
        return $q.reject(response);
      });
  }

  function globalAnnouncementsMarkAllRead() {
    return $http
      .post(`${apiEndpoint}/me/global_announcements/mark_all_read`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to mark all global announcements as read', response));
        return $q.reject(response);
      });
  }

  function searchUsers(query) {
    if (_.isNull(query) || _.isEmpty(query)) {
      throw new Error('"query" argument not specified or empty');
    }

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
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/make_admin`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to make the user an admin', response));
        return $q.reject(response);
      });
  }

  function revokeAdmin(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/revoke_admin`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to revoke admin status', response));
        return $q.reject(response);
      });
  }

  function getProjectMemberships(projectId) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }

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
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

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
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .delete(`${apiEndpoint}/projects/${projectId}/memberships/${userId}`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to remove team member from project', response));
        return $q.reject(response);
      });
  }

  function projectSetRole(projectId, userId, role) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }
    if (_.isNull(role) || _.isEmpty(role)) {
      throw new Error('"role" argument not specified or empty');
    }

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
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }
    if (_.isNull(role) || _.isEmpty(role)) {
      throw new Error('"role" argument not specified or empty');
    }

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
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/onboard_github`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to onboard user to GitHub ', response));
        return $q.reject(response);
      });
  }

  function userOffboardGitHub(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/offboard_github`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to offboard user from GitHub', response));
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

  function announcementMarkSticky(announcementId) {
    if (_.isNull(announcementId) || _.isEmpty(announcementId)) {
      throw new Error('"announcementId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/announcements/${announcementId}/mark_sticky`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to mark announcement as sticky', response));
        return $q.reject(response);
      });
  }

  function announcementUnmarkSticky(announcementId) {
    if (_.isNull(announcementId) || _.isEmpty(announcementId)) {
      throw new Error('"announcementId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/announcements/${announcementId}/unmark_sticky`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to unmark announcement as sticky', response));
        return $q.reject(response);
      });
  }

  function buildSimpleFetcher(path, errorDescriptor) {
    return function () {
      return $http
        .get(`${apiEndpoint}/${path}`)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to fetch ${errorDescriptor}`, response));
          return $q.reject(response);
        });
    };
  }

  function buildSimpleUpdater(path, errorDescriptor) {
    return function (data) {
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

      return $http
        .put(`${apiEndpoint}/${path}`, data)
        .then(response => {
          return response.data;
        })
        .catch(response => {
          logger.error(buildErrorMessageFromResponse(`Failed to update ${errorDescriptor}`, response));
          return $q.reject(response);
        });
    };
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
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }

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
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

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
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }
      if (_.isNull(data) || _.isEmpty(data)) {
        throw new Error('"data" argument not specified or empty');
      }

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
      if (_.isNull(id) || _.isEmpty(id)) {
        throw new Error('"id" argument not specified or empty');
      }

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

  function getKubernetesTokens(userId) {
    return $http
      .get(`${apiEndpoint}/kubernetes/tokens/${userId}`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error('Failed to fetch user kubernetes tokens – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function deleteKubernetesToken(userId, cluster) {
    return $http
      .delete(`${apiEndpoint}/kubernetes/tokens/${userId}/${cluster}`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to delete "'${cluster}'" kubernetes token for '${userId}'`, response));
        return $q.reject(response);
      });
  }

  function createOrUpdateKubernetesToken(user, data) {
    return $http
      .patch(`${apiEndpoint}/kubernetes/tokens/${user.id}/${data.cluster}`, {
        groups: data.groups
      })
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to create or update a "${data.cluster}" kubernetes token for ${user.id}`, response));
        return $q.reject(response);
      });
  }

  function getKubernetesTokensChangeset(cluster) {
    if (_.isNull(cluster) || _.isEmpty(cluster)) {
      throw new Error('"cluster" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/kubernetes/changeset/${cluster}`)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(`Failed to fetch kubernetes tokens changeset for "${cluster}" cluster – the API might be down. Try again later.`);
        return $q.reject(response);
      });
  }

  function syncKubernetesTokens(data) {
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/kubernetes/sync`, data)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Sync error', response));
        return $q.reject(response);
      });
  }

  function claimKubernetesToken(data) {
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/kubernetes/claim`, data)
      .then(response => {
        return response.data;
      })
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Claim error', response));
        return $q.reject(response);
      });
  }
};
