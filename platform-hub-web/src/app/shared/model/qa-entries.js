export const QaEntries = function (hubApiService) {
  'ngInject';

  const model = {};

  model.getAll = hubApiService.getQaEntries;
  model.get = hubApiService.getQaEntry;
  model.create = hubApiService.createQaEntry;
  model.update = hubApiService.updateQaEntry;
  model.delete = hubApiService.deleteQaEntry;

  return model;
};
