export const CostsReports = function (hubApiService) {
  'ngInject';

  const model = {};

  model.getAvailableDataFiles = hubApiService.getCostsReportsAvailableDataFiles;
  model.getAll = hubApiService.getCostsReports;
  model.get = hubApiService.getCostsReport;
  model.prepare = hubApiService.prepareCostsReport;
  model.create = hubApiService.createCostsReport;
  model.delete = hubApiService.deleteCostsReport;
  model.publish = hubApiService.publishCostsReport;

  return model;
};
