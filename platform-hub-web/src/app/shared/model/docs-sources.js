/* eslint camelcase: 0 */

export const DocsSources = function (hubApiService) {
  'ngInject';

  const model = {};

  model.kinds = {
    github_repo: 'GitHub repo',
    hosted_gitlab_repo: 'Hosted GitLab repo'
  };

  model.getAll = hubApiService.getDocsSources;
  model.get = hubApiService.getDocsSource;
  model.create = hubApiService.createDocsSource;
  model.update = hubApiService.updateDocsSource;
  model.delete = hubApiService.deleteDocsSource;
  model.syncAll = hubApiService.syncAllDocsSources;
  model.sync = hubApiService.syncDocsSource;

  return model;
};
