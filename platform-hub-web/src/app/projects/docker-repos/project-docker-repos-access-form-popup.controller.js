export const ProjectDockerReposAccessFormPopupController = function ($mdDialog, Projects, project, dockerRepo, projectMemberships, logger, _) {
  'ngInject';

  const ctrl = this;

  ctrl.project = project;
  ctrl.dockerRepo = dockerRepo;
  ctrl.projectMemberships = projectMemberships;

  ctrl.robotNamePrefix = dockerRepo.name.replace(/\//gi, '_');

  ctrl.robotNameRegex = '^[a-z]+[a-z0-9\\-_]*$';

  ctrl.saving = false;
  ctrl.robots = [];
  ctrl.users = [];

  ctrl.cancel = $mdDialog.cancel;
  ctrl.addRobot = addRobot;
  ctrl.removeRobot = removeRobot;
  ctrl.save = save;

  init();

  function init() {
    // Make copies as we'll be mutating!

    const robots = buildInitialRobots();
    angular.copy(robots, ctrl.robots);

    const users = buildInitialUsers();
    angular.copy(users, ctrl.users);
  }

  function buildInitialRobots() {
    const robots = _.get(dockerRepo, 'access.robots') || [];
    return robots.filter(r => r.status !== 'removing');
  }

  function buildInitialUsers() {
    const accessUsers = _.get(dockerRepo, 'access.users') || [];
    return projectMemberships.map(m => {
      const email = m.user.email;
      const accessEntry = _.find(accessUsers, u => u.username === email);

      return {
        username: email,
        enabled: accessEntry && accessEntry.status !== 'removing',
        writable: accessEntry && accessEntry.writable
      };
    });
  }

  function addRobot() {
    ctrl.robots.push({});
  }

  function removeRobot(ix) {
    ctrl.robots.splice(ix, 1);
  }

  function save() {
    if (ctrl.form.$invalid) {
      logger.error('Check the form for issues before saving');
      return;
    }

    const errors = validate();
    if (errors.length > 0) {
      logger.error(errors.join('<br />'));
      return;
    }

    ctrl.saving = true;

    const robots = ctrl.robots.map(r => {
      let username = r.username;
      if (!username.startsWith(ctrl.robotNamePrefix)) {
        username = `${ctrl.robotNamePrefix}_${username}`;
      }
      return {username};
    });

    const users = _.filter(ctrl.users, ['enabled', true]).map(u => {
      return {
        username: u.username,
        writable: Boolean(u.writable)
      };
    });

    Projects
      .updateAccessDockerRepo(
        project.id,
        dockerRepo.id,
        robots,
        users
      ).then(() => {
        logger.success('Updates to access policy submitted and will be processed in the background');
        $mdDialog.hide();
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }

  function validate() {
    const errors = [];

    // Check for unique robot names (case-insensitive)
    // Note: we expect only lowercase letters anyway
    const uniqueUsernames = _.uniqBy(ctrl.robots, r => r.username);
    if (ctrl.robots.length !== uniqueUsernames.length) {
      errors.push('Duplicate robot account usernames detected');
    }

    return errors;
  }
};
