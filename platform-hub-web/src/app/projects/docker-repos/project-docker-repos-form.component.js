export const ProjectDockerReposFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./project-docker-repos-form.html'),
  controller: ProjectDockerReposFormController
};

function ProjectDockerReposFormController($q, $state, Projects, logger) {
  'ngInject';

  const ctrl = this;

  const projectId = ctrl.transition.params().projectId;

  ctrl.fieldNameRegex = '^[a-z]+[a-z0-9\\-_\\/]*$';

  ctrl.projectId = projectId;
  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.project = null;
  ctrl.services = null;
  ctrl.repo = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    const projectPromise = Projects.get(projectId);

    const servicesPromise = Projects.getServices(projectId);

    $q.all([projectPromise, servicesPromise])
      .then(([project, services]) => {
        ctrl.project = project;
        ctrl.services = services;
        ctrl.repo = {};
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    if (ctrl.repoForm.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    ctrl.saving = true;

    Projects
      .createDockerRepo(projectId, ctrl.repo)
      .then(() => {
        logger.success('New Docker repo requested - refresh your project\'s Docker repos tab to see updates');
        $state.go('projects.detail', {id: projectId});
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
