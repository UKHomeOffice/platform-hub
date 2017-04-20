export const SupportRequestsOverviewComponent = {
  template: require('./support-requests-overview.html'),
  controller: SupportRequestsOverviewController
};

function SupportRequestsOverviewController($q, hubApiService, UserScopes) {
  'ngInject';

  const ctrl = this;

  ctrl.loading = this;
  ctrl.templates = [];
  ctrl.gitHubRepos = [];

  ctrl.templateIsVisible = templateIsVisible;

  init();

  function init() {
    loadData();
  }

  function loadData() {
    ctrl.loading = true;
    ctrl.templates = [];
    ctrl.gitHubRepos = [];

    const templatesFetcher = hubApiService
      .getSupportRequestTemplates()
      .then(templates => {
        ctrl.templates = templates;
      });

    const reposFetcher = hubApiService
      .getSupportRequestTemplateGitHubRepos()
      .then(repos => {
        ctrl.gitHubRepos = repos;
      });

    $q
      .all([templatesFetcher, reposFetcher])
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function templateIsVisible(template) {
    return UserScopes.isVisibleToCurrentUser(template.user_scope);
  }
}
