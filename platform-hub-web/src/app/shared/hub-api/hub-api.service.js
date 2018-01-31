/* eslint camelcase: 0, object-shorthand: 0 */

export const hubApiService = function ($rootScope, $http, $q, logger, apiEndpoint, apiHelpers, apiPagination, apiRequestBuilders, _) {
  'ngInject';

  const buildErrorMessageFromResponse = apiHelpers.buildErrorMessageFromResponse;
  const handle4xxError = apiHelpers.handle4xxError;

  const withPaginationParams = apiPagination.withPaginationParams;
  const handlePaginatedResponse = apiPagination.handlePaginatedResponse;

  const buildSimpleFetcher = apiRequestBuilders.buildSimpleFetcher;
  const buildSimplePoster = apiRequestBuilders.buildSimplePoster;
  const buildSimpleUpdater = apiRequestBuilders.buildSimpleUpdater;
  const buildCollectionFetcher = apiRequestBuilders.buildCollectionFetcher;
  const buildSubCollectionFetcher = apiRequestBuilders.buildSubCollectionFetcher;
  const buildSubSubCollectionFetcher = apiRequestBuilders.buildSubSubCollectionFetcher;
  const buildResourceFetcher = apiRequestBuilders.buildResourceFetcher;
  const buildSubResourceFetcher = apiRequestBuilders.buildSubResourceFetcher;
  const buildSubSubResourceFetcher = apiRequestBuilders.buildSubSubResourceFetcher;
  const buildResourceCreator = apiRequestBuilders.buildResourceCreator;
  const buildSubResourceCreator = apiRequestBuilders.buildSubResourceCreator;
  const buildResourceUpdater = apiRequestBuilders.buildResourceUpdater;
  const buildSubResourceUpdater = apiRequestBuilders.buildSubResourceUpdater;
  const buildResourceDeletor = apiRequestBuilders.buildResourceDeletor;
  const buildSubResourceDeletor = apiRequestBuilders.buildSubResourceDeletor;

  const service = {};

  service.getMe = getMe;
  service.getIdentityFlowStartEndpoint = getIdentityFlowStartEndpoint;
  service.deleteMeIdentity = deleteMeIdentity;
  service.completeHubOnboarding = completeHubOnboarding;
  service.completeServicesOnboarding = completeServicesOnboarding;
  service.agreeTermsOfService = agreeTermsOfService;
  service.globalAnnouncementsMarkAllRead = globalAnnouncementsMarkAllRead;

  service.getUsers = buildCollectionFetcher('users', true);
  service.getUser = buildResourceFetcher('users');
  service.searchUsers = searchUsers;
  service.getUserIdentities = buildSubCollectionFetcher('users', 'identities');
  service.makeAdmin = makeAdmin;
  service.revokeAdmin = revokeAdmin;
  service.makeLimitedAdmin = makeLimitedAdmin;
  service.revokeLimitedAdmin = revokeLimitedAdmin;
  service.activateUser = activateUser;
  service.deactivateUser = deactivateUser;

  service.getProjects = buildCollectionFetcher('projects');
  service.getProject = buildResourceFetcher('projects');
  service.createProject = buildResourceCreator('projects');
  service.updateProject = buildResourceUpdater('projects');
  service.deleteProject = buildResourceDeletor('projects');
  service.getProjectMemberships = buildSubCollectionFetcher('projects', 'memberships');
  service.addProjectMembership = addProjectMembership;
  service.removeProjectMembership = removeProjectMembership;
  service.projectMembershipRoleCheck = projectMembershipRoleCheck;
  service.projectSetMembershipRole = projectSetMembershipRole;
  service.projectUnsetMembershipRole = projectUnsetMembershipRole;
  service.getProjectKubernetesClusters = buildSubCollectionFetcher('projects', 'kubernetes_clusters');
  service.getProjectKubernetesGroups = getProjectKubernetesGroups;
  service.getProjectKubernetesUserTokens = buildSubCollectionFetcher('projects', 'kubernetes_user_tokens');
  service.getProjectKubernetesUserToken = buildSubResourceFetcher('projects', 'kubernetes_user_tokens');
  service.createProjectKubernetesUserToken = createProjectKubernetesUserToken;
  service.updateProjectKubernetesUserToken = updateProjectKubernetesUserToken;
  service.deleteProjectKubernetesUserToken = buildSubResourceDeletor('projects', 'kubernetes_user_tokens');
  service.getProjectBills = buildSubCollectionFetcher('projects', 'bills');

  service.getProjectServices = buildSubCollectionFetcher('projects', 'services');
  service.getProjectService = buildSubResourceFetcher('projects', 'services');
  service.createProjectService = buildSubResourceCreator('projects', 'services');
  service.updateProjectService = buildSubResourceUpdater('projects', 'services');
  service.deleteProjectService = buildSubResourceDeletor('projects', 'services');
  service.getProjectServiceKubernetesGroups = getProjectServiceKubernetesGroups;
  service.getProjectServiceKubernetesRobotTokens = buildSubSubCollectionFetcher('projects', 'services', 'kubernetes_robot_tokens');
  service.getProjectServiceKubernetesRobotToken = buildSubSubResourceFetcher('projects', 'services', 'kubernetes_robot_tokens');
  service.createProjectServiceKubernetesRobotToken = createProjectServiceKubernetesRobotToken;
  service.updateProjectServiceKubernetesRobotToken = updateProjectServiceKubernetesRobotToken;
  service.deleteProjectServiceKubernetesRobotToken = deleteProjectServiceKubernetesRobotToken;

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
  service.announcementResend = announcementResend;

  service.getAnnouncementTemplates = buildCollectionFetcher('announcement_templates');
  service.getAnnouncementTemplate = buildResourceFetcher('announcement_templates');
  service.createAnnouncementTemplate = buildResourceCreator('announcement_templates');
  service.updateAnnouncementTemplate = buildResourceUpdater('announcement_templates');
  service.deleteAnnouncementTemplate = buildResourceDeletor('announcement_templates');
  service.getAnnouncementTemplateFormFieldTypes = buildSimpleFetcher('announcement_templates/form_field_types', 'field types');
  service.previewAnnouncementTemplate = previewAnnouncementTemplate;

  service.getKubernetesClusters = buildCollectionFetcher('kubernetes/clusters');
  service.getKubernetesCluster = buildResourceFetcher('kubernetes/clusters');
  service.createKubernetesCluster = buildResourceCreator('kubernetes/clusters');
  service.updateKubernetesCluster = buildResourceUpdater('kubernetes/clusters');
  service.allocateKubernetesCluster = allocateKubernetesCluster;
  service.getKubernetesClusterAllocations = buildSubCollectionFetcher('kubernetes/clusters', 'allocations');
  service.getKubernetesClusterRobotTokens = buildSubCollectionFetcher('kubernetes/clusters', 'robot_tokens', true);
  service.getKubernetesClusterUserTokens = buildSubCollectionFetcher('kubernetes/clusters', 'user_tokens', true);

  service.getKubernetesGroups = buildCollectionFetcher('kubernetes/groups', true);
  service.getKubernetesGroup = buildResourceFetcher('kubernetes/groups');
  service.createKubernetesGroup = buildResourceCreator('kubernetes/groups');
  service.updateKubernetesGroup = buildResourceUpdater('kubernetes/groups');
  service.deleteKubernetesGroup = buildResourceDeletor('kubernetes/groups');
  service.allocateKubernetesGroup = allocateKubernetesGroup;
  service.getKubernetesGroupAllocations = buildSubCollectionFetcher('kubernetes/groups', 'allocations');
  service.getKubernetesGroupTokens = buildSubCollectionFetcher('kubernetes/groups', 'tokens', true);

  service.getKubernetesToken = buildResourceFetcher('kubernetes/tokens');
  service.deleteKubernetesToken = buildResourceDeletor('kubernetes/tokens');

  service.getKubernetesUserTokens = getKubernetesUserTokens;
  service.createKubernetesUserToken = createKubernetesUserToken;
  service.updateKubernetesUserToken = updateKubernetesUserToken;

  service.getKubernetesRobotTokens = getKubernetesRobotTokens;
  service.createKubernetesRobotToken = createKubernetesRobotToken;
  service.updateKubernetesRobotToken = updateKubernetesRobotToken;

  service.getKubernetesTokensChangeset = getKubernetesTokensChangeset;
  service.syncKubernetesTokens = syncKubernetesTokens;
  service.revokeKubernetesToken = revokeKubernetesToken;
  service.escalatePrivilegeForKubernetesTokens = escalatePrivilegeForKubernetesTokens;

  service.getKubernetesNamespaces = getKubernetesNamespaces;
  service.getKubernetesNamespace = buildResourceFetcher('kubernetes/namespaces');
  service.createKubernetesNamespace = buildResourceCreator('kubernetes/namespaces');
  service.updateKubernetesNamespace = buildResourceUpdater('kubernetes/namespaces');
  service.deleteKubernetesNamespace = buildResourceDeletor('kubernetes/namespaces');

  service.getFeatureFlags = buildSimpleFetcher('feature_flags', 'feature flags');
  service.updateFeatureFlag = buildResourceUpdater('feature_flags');

  service.deleteAllocation = buildResourceDeletor('allocations');

  service.getCostsReportsAvailableDataFiles = buildSimpleFetcher('costs_reports/available_data_files');
  service.getCostsReports = buildCollectionFetcher('costs_reports');
  service.getCostsReport = buildResourceFetcher('costs_reports');
  service.prepareCostsReport = buildSimplePoster('costs_reports/prepare', 'prepare costs report');
  service.createCostsReport = buildResourceCreator('costs_reports');
  service.deleteCostsReport = buildResourceDeletor('costs_reports');
  service.publishCostsReport = publishCostsReport;

  return service;

  function getMe() {
    return $http
      .get(`${apiEndpoint}/me`)
      .then(response => response.data)
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
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to complete hub onboarding', response));
        return $q.reject(response);
      });
  }

  function completeServicesOnboarding() {
    return $http
      .post(`${apiEndpoint}/me/complete_services_onboarding`)
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to complete services onboarding', response));
        return $q.reject(response);
      });
  }

  function agreeTermsOfService() {
    return $http
      .post(`${apiEndpoint}/me/agree_terms_of_service`)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Error occurred whilst agreeing to terms of service', response));
        return $q.reject(response);
      });
  }

  function globalAnnouncementsMarkAllRead() {
    return $http
      .post(`${apiEndpoint}/me/global_announcements/mark_all_read`)
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to mark all global announcements as read', response));
        return $q.reject(response);
      });
  }

  function searchUsers(query, include_deactivated = false) {
    if (_.isNull(query) || _.isEmpty(query)) {
      throw new Error('"query" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/users/search/${query}?include_deactivated=${include_deactivated}`)
      .then(response => response.data)
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
        logger.error(buildErrorMessageFromResponse('Failed to make the user a hub admin', response));
        return $q.reject(response);
      });
  }

  function revokeAdmin(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/revoke_admin`)
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to revoke hub admin status', response));
        return $q.reject(response);
      });
  }

  function makeLimitedAdmin(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/make_limited_admin`)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to make the user a hub limited admin', response));
        return $q.reject(response);
      });
  }

  function revokeLimitedAdmin(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/revoke_limited_admin`)
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to revoke hub limited admin status', response));
        return $q.reject(response);
      });
  }

  function activateUser(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/activate`)
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to activate user', response));
        return $q.reject(response);
      });
  }

  function deactivateUser(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/deactivate`)
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to deactivate user', response));
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
      .then(response => response.data)
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

  function projectMembershipRoleCheck(projectId, role) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(role) || _.isEmpty(role)) {
      throw new Error('"role" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/projects/${projectId}/memberships/role_check/${role}`)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to check if user is ${role} for the specific project`, response));
        return $q.reject(response);
      });
  }

  function projectSetMembershipRole(projectId, userId, role) {
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
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to set project team role', response));
        return $q.reject(response);
      });
  }

  function projectUnsetMembershipRole(projectId, userId, role) {
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
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to unset project team role', response));
        return $q.reject(response);
      });
  }

  function getProjectKubernetesGroups(projectId, target) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/projects/${projectId}/kubernetes_groups`, {
        params: {
          target
        }
      })
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to fetch kubernetes groups for project', response));
        return $q.reject(response);
      });
  }

  function createProjectKubernetesUserToken(projectId, data) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/projects/${projectId}/kubernetes_user_tokens`, {
        user_token: {
          cluster_name: data.cluster.name,
          groups: data.groups,
          user_id: data.user.id
        }
      })
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to create new user token for project', response));
        return $q.reject(response);
      });
  }

  function updateProjectKubernetesUserToken(projectId, tokenId, data) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(tokenId) || _.isEmpty(tokenId)) {
      throw new Error('"tokenId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .patch(`${apiEndpoint}/projects/${projectId}/kubernetes_user_tokens/${tokenId}`, {
        user_token: {
          groups: data.groups
        }
      })
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to update user token for project', response));
        return $q.reject(response);
      });
  }

  function getProjectServiceKubernetesGroups(projectId, serviceId, target) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(serviceId) || _.isEmpty(serviceId)) {
      throw new Error('"serviceId" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/projects/${projectId}/services/${serviceId}/kubernetes_groups`, {
        params: {
          target
        }
      })
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to fetch kubernetes groups for service', response));
        return $q.reject(response);
      });
  }

  function createProjectServiceKubernetesRobotToken(projectId, serviceId, data) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(serviceId) || _.isEmpty(serviceId)) {
      throw new Error('"serviceId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/projects/${projectId}/services/${serviceId}/kubernetes_robot_tokens`, {
        robot_token: {
          service_id: serviceId,
          cluster_name: data.cluster.name,
          groups: data.groups,
          name: data.name,
          description: data.description
        }
      })
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to create new token for project service', response));
        return $q.reject(response);
      });
  }

  function updateProjectServiceKubernetesRobotToken(projectId, serviceId, tokenId, data) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(serviceId) || _.isEmpty(serviceId)) {
      throw new Error('"serviceId" argument not specified or empty');
    }
    if (_.isNull(tokenId) || _.isEmpty(tokenId)) {
      throw new Error('"tokenId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .patch(`${apiEndpoint}/projects/${projectId}/services/${serviceId}/kubernetes_robot_tokens/${tokenId}`, {
        robot_token: {
          groups: data.groups,
          description: data.description
        }
      })
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to update token for project service', response));
        return $q.reject(response);
      });
  }

  function deleteProjectServiceKubernetesRobotToken(projectId, serviceId, tokenId) {
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }
    if (_.isNull(serviceId) || _.isEmpty(serviceId)) {
      throw new Error('"serviceId" argument not specified or empty');
    }
    if (_.isNull(tokenId) || _.isEmpty(tokenId)) {
      throw new Error('"tokenId" argument not specified or empty');
    }

    return $http
      .delete(`${apiEndpoint}/projects/${projectId}/services/${serviceId}/kubernetes_robot_tokens/${tokenId}`)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to delete token', response));
        return $q.reject(response);
      });
  }

  function userOnboardGitHub(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/onboard_github`)
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to onboard user to GitHub', response));
        return $q.reject(response);
      });
  }

  function userOffboardGitHub(userId) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/users/${userId}/offboard_github`)
      .then(handle4xxError)
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
      .then(handle4xxError)
      .then(response => response.data)
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
      .then(handle4xxError)
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
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to unmark announcement as sticky', response));
        return $q.reject(response);
      });
  }

  function announcementResend(announcementId) {
    if (_.isNull(announcementId) || _.isEmpty(announcementId)) {
      throw new Error('"announcementId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/announcements/${announcementId}/resend`)
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to mark announcement for resending', response));
        return $q.reject(response);
      });
  }

  function previewAnnouncementTemplate(templates, data) {
    if (_.isNull(templates) || _.isEmpty(templates)) {
      throw new Error('"templates" argument not specified or empty');
    }

    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/announcement_templates/preview`, {
        templates: templates,
        data: data
      })
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to preview announcement template', response));
        return $q.reject(response);
      });
  }

  function allocateKubernetesCluster(clusterId, projectId) {
    if (_.isNull(clusterId) || _.isEmpty(clusterId)) {
      throw new Error('"clusterId" argument not specified or empty');
    }
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/kubernetes/clusters/${clusterId}/allocate`, {
        project_id: projectId
      })
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to allocate Kubernetes cluster to a project`, response));
        return $q.reject(response);
      });
  }

  function allocateKubernetesGroup(groupId, projectId, serviceId) {
    if (_.isNull(groupId) || _.isEmpty(groupId)) {
      throw new Error('"groupId" argument not specified or empty');
    }
    if (_.isNull(projectId) || _.isEmpty(projectId)) {
      throw new Error('"projectId" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/kubernetes/groups/${groupId}/allocate`, {
        project_id: projectId,
        service_id: serviceId
      })
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to allocate Kubernetes RBAC group to a project or service`, response));
        return $q.reject(response);
      });
  }

  function getKubernetesUserTokens(userId, page = 1) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/kubernetes/tokens`, {
        params: withPaginationParams(
          {
            kind: 'user',
            user_id: userId
          },
          page
        )
      })
      .then(handlePaginatedResponse)
      .catch(response => {
        logger.error('Failed to fetch user kubernetes tokens – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function createKubernetesUserToken(userId, data) {
    if (_.isNull(userId) || _.isEmpty(userId)) {
      throw new Error('"userId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/kubernetes/tokens`, {
        kind: 'user',
        user_id: userId,
        project_id: data.project.id,
        cluster_name: data.cluster.name,
        groups: data.groups
      })
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to create kubernetes token`, response));
        return $q.reject(response);
      });
  }

  function updateKubernetesUserToken(tokenId, data) {
    if (_.isNull(tokenId) || _.isEmpty(tokenId)) {
      throw new Error('"tokenId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .patch(`${apiEndpoint}/kubernetes/tokens/${tokenId}`, {
        kind: 'user',
        groups: data.groups
      })
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to update a "${data.cluster}" kubernetes token`, response));
        return $q.reject(response);
      });
  }

  function getKubernetesRobotTokens(cluster, page = 1) {
    if (_.isNull(cluster) || _.isEmpty(cluster)) {
      throw new Error('"cluster" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/kubernetes/tokens`, {
        params: withPaginationParams(
          {
            kind: 'robot',
            cluster_name: cluster
          },
          page
        )
      })
      .then(handlePaginatedResponse)
      .catch(response => {
        logger.error('Failed to fetch robot kubernetes tokens – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function createKubernetesRobotToken(serviceId, data) {
    if (_.isNull(serviceId) || _.isEmpty(serviceId)) {
      throw new Error('"serviceId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/kubernetes/tokens`, {
        kind: 'robot',
        service_id: serviceId,
        cluster_name: data.cluster.name,
        groups: data.groups,
        name: data.name,
        description: data.description
      })
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to create a kubernetes robot token`, response));
        return $q.reject(response);
      });
  }

  function updateKubernetesRobotToken(tokenId, data) {
    if (_.isNull(tokenId) || _.isEmpty(tokenId)) {
      throw new Error('"tokenId" argument not specified or empty');
    }
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .patch(`${apiEndpoint}/kubernetes/tokens/${tokenId}`, {
        kind: 'robot',
        groups: data.groups,
        description: data.description
      })
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse(`Failed to update a "${data.name}" kubernetes robot token`, response));
        return $q.reject(response);
      });
  }

  function getKubernetesTokensChangeset(cluster) {
    if (_.isNull(cluster) || _.isEmpty(cluster)) {
      throw new Error('"cluster" argument not specified or empty');
    }

    return $http
      .get(`${apiEndpoint}/kubernetes/changeset/${cluster}`)
      .then(response => response.data)
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
      .then(handle4xxError)
      .then(response => response.data)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Sync error', response));
        return $q.reject(response);
      });
  }

  function revokeKubernetesToken(data) {
    if (_.isNull(data) || _.isEmpty(data)) {
      throw new Error('"data" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/kubernetes/revoke`, data)
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Revocation error', response));
        return $q.reject(response);
      });
  }

  function escalatePrivilegeForKubernetesTokens(tokenId, group, expiresInSecs) {
    if (_.isNull(tokenId) || _.isEmpty(tokenId)) {
      throw new Error('"tokenId" argument not specified or empty');
    }
    if (_.isNull(group) || _.isEmpty(group)) {
      throw new Error('"group" argument not specified or empty');
    }
    if (_.isNull(expiresInSecs) || expiresInSecs < 1) {
      throw new Error('"expiresInSecs" argument not specified or invalid');
    }

    return $http
      .patch(`${apiEndpoint}/kubernetes/tokens/${tokenId}/escalate`, {
        privileged_group: group,
        expires_in_secs: expiresInSecs
      })
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to escalate privilege on Kube token', response));
        return $q.reject(response);
      });
  }

  function getKubernetesNamespaces(params, page = 1) {
    return $http
      .get(`${apiEndpoint}/kubernetes/namespaces`, {
        params: withPaginationParams(params, page)
      })
      .then(handlePaginatedResponse)
      .catch(response => {
        logger.error('Failed to fetch kubernetes namespaces – the API might be down. Try again later.');
        return $q.reject(response);
      });
  }

  function publishCostsReport(id) {
    if (_.isNull(id) || _.isEmpty(id)) {
      throw new Error('"id" argument not specified or empty');
    }

    return $http
      .post(`${apiEndpoint}/costs_reports/${id}/publish`, {})
      .then(handle4xxError)
      .catch(response => {
        logger.error(buildErrorMessageFromResponse('Failed to publish report', response));
        return $q.reject(response);
      });
  }
};
