export const PinnedHelpEntries = function (hubApiService) {
  'ngInject';

  const model = {};

  model.get = hubApiService.getPinnedHelpEntries;
  model.update = hubApiService.updatePinnedHelpEntries;

  return model;
};
