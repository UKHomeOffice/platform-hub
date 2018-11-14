export const projectDockerReposAccessFormPopupService = function ($document, $mdDialog) {
  'ngInject';

  const service = {};

  service.open = open;

  return service;

  function open(project, dockerRepo, projectMemberships, targetEvent) {
    return $mdDialog.show({
      template: require('./project-docker-repos-access-form-popup.html'),
      controller: 'ProjectDockerReposAccessFormPopupController',
      controllerAs: '$ctrl',
      parent: angular.element($document.body),
      targetEvent: targetEvent,  // eslint-disable-line object-shorthand
      clickOutsideToClose: false,
      escapeToClose: false,
      locals: {
        project,
        dockerRepo,
        projectMemberships
      }
    });
  }
};
