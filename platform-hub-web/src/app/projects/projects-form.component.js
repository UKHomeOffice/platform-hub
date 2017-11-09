export const ProjectsFormComponent = {
  bindings: {
    transition: '<'
  },
  template: require('./projects-form.html'),
  controller: ProjectsFormController
};

function ProjectsFormController($state, Projects, logger) {
  'ngInject';

  const ctrl = this;

  const id = ctrl.transition && ctrl.transition.params().id;

  ctrl.loading = true;
  ctrl.saving = false;
  ctrl.isNew = true;
  ctrl.project = null;

  ctrl.createOrUpdate = createOrUpdate;

  init();

  function init() {
    ctrl.isNew = !id;

    if (ctrl.isNew) {
      ctrl.project = {};
      ctrl.loading = false;
    } else {
      loadProject();
    }
  }

  function loadProject() {
    ctrl.loading = true;
    ctrl.project = null;

    Projects
      .get(id)
      .then(project => {
        ctrl.project = project;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function createOrUpdate() {
    ctrl.saving = true;

    if (ctrl.isNew) {
      Projects
        .create(ctrl.project)
        .then(project => {
          logger.success('New project created');
          $state.go('projects.detail', {id: project.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    } else {
      Projects
        .update(ctrl.project.id, ctrl.project)
        .then(project => {
          logger.success('Project updated');
          $state.go('projects.detail', {id: project.id});
        })
        .finally(() => {
          ctrl.saving = false;
        });
    }
  }
}
